{ config, depot, lib, ... }:

let
  inherit (depot.lib.meta) domain;
  frontendDomain = "consul-remote.internal.${domain}";

  inherit (config.reflection.interfaces.vstub) addr;
in

{
  services.nginx.virtualHosts.${frontendDomain} = depot.lib.nginx.vhosts.proxy config.links.consulAgent.url // {
    listenAddresses = lib.singleton addr;
    enableACME = false;
    useACMEHost = "internal.${domain}";
  };

  consul.services.consul-remote = {
    unit = "consul";
    mode = "external";
    definition = {
      name = "consul-remote";
      address = addr;
      port = 443;
      checks = [
        {
          name = "Frontend";
          id = "service:consul-remote:frontend";
          http = "https://${addr}/v1/status/leader";
          tls_server_name = frontendDomain;
          header.Host = lib.singleton frontendDomain;
          interval = "60s";
        }
        {
          name = "Backend";
          id = "service:consul-remote:backend";
          http = "${config.links.consulAgent.url}/v1/status/leader";
          interval = "30s";
        }
      ];
    };
  };
}
