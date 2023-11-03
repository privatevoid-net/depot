{ config, cluster, depot, lib, ... }:

let
  link = cluster.config.links.garageS3;
in

{
  links.garageMetrics.protocol = "http";

  services.garage.settings.admin.api_bind_addr = config.links.garageMetrics.tuple;

  services.nginx.virtualHosts = {
    ${link.hostname} = depot.lib.nginx.vhosts.basic // {
      locations = {
        "/".proxyPass = cluster.config.hostLinks.${config.networking.hostName}.garageS3.url;

        "= /health".proxyPass = config.links.garageMetrics.url;
      };
    };
  };
  security.acme.certs.${link.hostname} = {
    dnsProvider = "pdns";
    webroot = lib.mkForce null;
  };

  consul.services.garage = {
    mode = "external";
    definition = rec {
      name = "garage";
      address = depot.reflection.interfaces.primary.addrPublic;
      inherit (link) port;
      checks = [
        {
          name = "Frontend";
          id = "service:garage:frontend";
          interval = "60s";
          http = "https://${address}/health";
          tls_server_name = link.hostname;
          header.Host = lib.singleton link.hostname;
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
