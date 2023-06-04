{ config, cluster, lib, tools, ... }:

let
  inherit (lib) flip pipe mapAttrsToList range recursiveUpdate substring;

  inherit (tools.meta) domain;
  inherit (cluster.config) vars;

  mapTargets = mapAttrsToList (name: value: value // { name = "default/${name}"; });

  mkSecretTargets = amount: map (flip pipe [
    toString
    (num: let
      prefix = "SECRET_MONITORING_BLACKBOX_TARGET_${num}";
    in {
      name = "secret/\${${prefix}_NAME}";
      module = "\${${prefix}_MODULE}";
      address = "\${${prefix}_ADDRESS}";
    })
  ]) (range 1 1);

  probeId = pipe "blackbox-probe-${domain}-${vars.hostName}" [
    (builtins.hashString "md5")
    (substring 0 8)
  ];

  probeUserAgent = "Private Void Monitoring Probe ${probeId}";

  defaultHttpHeaders = {
    User-Agent = probeUserAgent;
  };

  relabel = from: to: {
    source_labels = [ from ];
    target_label = to;
  };
in

{
  services.grafana-agent.settings.integrations.blackbox = {
    enabled = true;
    instance = vars.hostName;
    scrape_interval = "600s";
    relabel_configs = [
      (relabel "__param_module" "module")
      (relabel "__param_target" "target")
      {
        target_label = "probe_id";
        replacement = probeId;
      }
    ];
    blackbox_config.modules = rec {
      http2xx = {
        prober = "http";
        http = {
          headers = defaultHttpHeaders;
          preferred_ip_protocol = "ip4";
        };
      };
      https2xx = recursiveUpdate http2xx {
        http.fail_if_not_ssl = true;
      };
      tcpConnect = {
        prober = "tcp";
        tcp = {
          preferred_ip_protocol = "ip4";
        };
      };
      ircConnect = recursiveUpdate tcpConnect {
        tcp.query_response = [
          { send = "NICK probe"; }
          { send = "USER probe probe probe :${probeUserAgent}"; }
          { send = "PING probe${probeId}"; }
          { expect = "PONG .* :probe${probeId}"; }
          { send = "QUIT"; }
        ];
      };
      ircsConnect = recursiveUpdate ircConnect {
        tcp.tls = true;
      };
    };
    blackbox_targets = let
      regularTargets = mapTargets cluster.config.monitoring.blackbox.targets;
      secretTargets = mkSecretTargets 1;
    in regularTargets ++ secretTargets;
  };

  age.secrets = {
    grafana-agent-blackbox-secret-monitoring.file = ./secrets/secret-monitoring/blackbox.age;
  };

  systemd.services.grafana-agent.serviceConfig = {
    EnvironmentFile = config.age.secrets.grafana-agent-blackbox-secret-monitoring.path;
  };
}
