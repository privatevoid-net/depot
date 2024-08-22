{ config, cluster, depot, ... }:

let
  inherit (depot.lib.meta) domain;
  inherit (config.networking) hostName;
  inherit (cluster.config) hostLinks;
  cfg = cluster.config.services.consul;

  hl = hostLinks.${hostName}.consul;
in

{
  links.consulAgent.protocol = "http";

  services.consul = {
    enable = true;
    webUi = true;
    package = depot.packages.consul;
    extraConfig = {
      datacenter = "eu-central";
      domain = "sd-magic.${domain}.";
      recursors = [ "127.0.0.1" cluster.config.links.dnsResolver.ipv4 ];
      server = true;
      node_name = config.networking.hostName;
      bind_addr = hl.ipv4;
      ports.serf_lan = hl.port;
      retry_join = map (hostName: hostLinks.${hostName}.consul.tuple) (cfg.otherNodes.agent hostName);
      bootstrap_expect = builtins.length cfg.nodes.agent;
      addresses.http = config.links.consulAgent.ipv4;
      ports.http = config.links.consulAgent.port;
      acl = {
        enabled = true;
        default_policy = "deny";
      };
    };
  };

  systemd.services = {
    consul.serviceConfig.Type = "notify";
    consul-load-smt = {
      wantedBy = [ "consul.service" ];
      after = [ "consul.service" ];
      environment.CONSUL_HTTP_ADDR = config.links.consulAgent.tuple;
      path = [
        config.services.consul.package
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        while ! test -e /run/locksmith/consul-systemManagementToken; do
          echo Waiting for System Management Token
          systemctl start locksmith.service
          sleep 5
        done
        export CONSUL_HTTP_TOKEN_FILE=/run/locksmith/consul-systemManagementToken
        consul acl set-agent-token default "$(< /run/locksmith/consul-systemManagementToken)" # TODO: don't leak token on cmdline
      '';
    };
  };

  services.grafana-agent.settings.integrations.consul_exporter = {
    enabled = true;
    instance = hostName;
    server = config.links.consulAgent.url;
  };
}
