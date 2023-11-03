{ config, cluster, depot, lib, ... }:

let
  inherit (depot.lib.meta) domain;
in

{
  links.garageMetrics.protocol = "http";

  services.garage.settings.admin.api_bind_addr = config.links.garageMetrics.tuple;

  services.nginx.virtualHosts = {
    "garage.${domain}" = depot.lib.nginx.vhosts.basic // {
      locations = {
        "/".proxyPass = cluster.config.hostLinks.${config.networking.hostName}.garageS3.url;

        "= /health".proxyPass = config.links.garageMetrics.url;
      };
    };
  };
  security.acme.certs."garage.${domain}" = {
    dnsProvider = "pdns";
    webroot = lib.mkForce null;
  };

  consul.services.garage = {
    mode = "external";
    definition = rec {
      name = "garage";
      address = depot.reflection.interfaces.primary.addrPublic;
      port = 443;
      checks = [
        rec {
          name = "Frontend";
          id = "service:garage:frontend";
          interval = "60s";
          http = "https://${address}/health";
          tls_server_name = "garage.${domain}";
          header.Host = lib.singleton tls_server_name;
        }
        {
          name = "Garage Node";
          id = "service:garage:node";
          interval = "5s";
          http = "${config.links.garageMetrics.url}/health";
        }
      ];
    };
  };
}
