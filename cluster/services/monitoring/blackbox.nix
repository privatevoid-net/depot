{ cluster, config, lib, depot, pkgs, ... }:

let
  inherit (lib) pipe mapAttrsToList recursiveUpdate substring;
  inherit (depot.lib.meta) domain;

  mapTargets = mapAttrsToList (name: value: value // { inherit name; });

  probeId = pipe "blackbox-probe-${domain}-${config.networking.hostName}" [
    (builtins.hashString "md5")
    (substring 0 8)
  ];

  probeUserAgent = "Private Void Monitoring Probe ${probeId}";

  defaultHttpHeaders = {
    User-Agent = probeUserAgent;
  };

  blackboxModules = rec {
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
    nextcloudStatus = recursiveUpdate https2xx {
      http = {
        fail_if_body_not_matches_regexp = [
          ''"installed":true''
          ''"maintenance":false''
        ];
      };
    };
    sshConnect = recursiveUpdate tcpConnect {
      tcp.query_response = [
        { expect = "^SSH-2.0"; }
        { send = "SSH-2.0-PrivateVoidProbe_${probeId}"; }
      ];
    };
  };
  blackboxConfigFile = pkgs.writeText "blackbox-config.json" (builtins.toJSON {
    modules = blackboxModules;
  });

  relabelConfigForGroup = group: ''
    rule {
      target_label = "probe_id"
      replacement = ${builtins.toJSON probeId}
    }

    rule {
      source_labels = ["__param_module"]
      target_label = "module"
    }

    rule {
      source_labels = ["__param_target"]
      target_label = "target"
    }

    rule {
      source_labels = ["job"]
      target_label = "target_name"
      regex = "integrations/blackbox/(.*)"
      replacement = "$1"
    }

    rule {
      target_label = "blackbox_group"
      replacement = ${builtins.toJSON group}
    }

    rule {
      source_labels = ["job"]
      target_label = "job"
      regex = "integrations/blackbox/(.*)"
      replacement = "integrations/blackbox/${group}/$1"
    }
  '';
in

{
  age.secrets = {
    blackboxSecretMonitoring.file = ./secrets/secret-monitoring/blackbox.age;
  };

  systemd.services.alloy.serviceConfig.EnvironmentFile = [ config.age.secrets.blackboxSecretMonitoring.path ];

  services.alloy.metrics.integrations = {
    blackbox = {
      exporter = "blackbox";
      name = "blackbox/default";
      scrapeInterval = 600;
      settings = {
        config_file = blackboxConfigFile;
        targets = mapTargets cluster.config.monitoring.blackbox.targets;
      };
      relabelConfigText = relabelConfigForGroup "default";
    };

    secretMonitoring = {
      exporter = "blackbox";
      name = "blackbox/secret";
      scrapeInterval = 600;
      labels.probe_id = probeId;
      settings.config_file = blackboxConfigFile;
      configText = ''
        targets = encoding.from_json(coalesce(encoding.from_base64(sys.env("BLACKBOX_SECRET_MONITORING_CONFIG")),"[]"))
      '';
      relabelConfigText = relabelConfigForGroup "secret";
    };
  };
}
