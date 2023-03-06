{ config, cluster, hosts, lib, tools, ... }:

let
  inherit (tools.meta) domain;
  inherit (config.networking) hostName;

  hyprspaceConfig = hosts.${hostName}.hypr;
  frontendDomain = "consul-remote.internal.${domain}";
in

{
  services.nginx.virtualHosts.${frontendDomain} = tools.nginx.vhosts.proxy "http://127.0.0.1:8500" // {
    listenAddresses = lib.singleton hyprspaceConfig.addr;
    enableACME = false;
    useACMEHost = "internal.${domain}";
  };

  consul.services.consul-remote = {
    unit = "consul";
    mode = "external";
    definition = {
      name = "consul-remote";
      address = hyprspaceConfig.addr;
      port = 443;
      checks = [
        {
          name = "Frontend";
          id = "service:consul-remote:frontend";
          http = "https://${hyprspaceConfig.addr}/v1/status/leader";
          tls_server_name = frontendDomain;
          interval = "60s";
        }
        {
          name = "Backend";
          id = "service:consul-remote:backend";
          http = "http://127.0.0.1:8500/v1/status/leader";
          interval = "30s";
        }
      ];
    };
  };
}
