{ config, cluster, depot, lib, ... }:

let
  linkS3 = cluster.config.links.garageS3;
  linkWeb = cluster.config.links.garageWeb;
in

{
  links.garageMetrics.protocol = "http";

  services.garage.settings.admin.api_bind_addr = config.links.garageMetrics.tuple;

  services.nginx.virtualHosts = {
    ${linkS3.hostname} = depot.lib.nginx.vhosts.basic // {
      locations = {
        "/".proxyPass = cluster.config.hostLinks.${config.networking.hostName}.garageS3.url;

        "= /health".proxyPass = config.links.garageMetrics.url;
      };
      extraConfig = "client_max_body_size 4G;";
    };
    "${linkWeb.hostname}" = depot.lib.nginx.vhosts.basic // {
      serverName = "~^(.+)\.${lib.escapeRegex linkWeb.hostname}$";
      enableACME = false;
      useACMEHost = linkWeb.hostname;
      locations = {
        "/" = {
          proxyPass = cluster.config.hostLinks.${config.networking.hostName}.garageWeb.url;
          extraConfig = ''
            proxy_set_header Host "$1.${linkWeb.hostname}";
          '';
        };

        "= /.internal-api/garage/health" = {
          proxyPass = "${config.links.garageMetrics.url}/health";
        };
      };
    };
  };
  security.acme.certs = {
    ${linkS3.hostname} = {
      dnsProvider = "exec";
      webroot = lib.mkForce null;
    };
    ${linkWeb.hostname} = {
      domain = "*.${linkWeb.hostname}";
      dnsProvider = "exec";
      group = "nginx";
    };
  };
  consul.services = {
    garage = {
      mode = "external";
      definition = rec {
        name = "garage";
        address = depot.reflection.interfaces.primary.addrPublic;
        inherit (linkS3) port;
        checks = [
          {
            name = "Frontend";
            id = "service:garage:frontend";
            interval = "60s";
            http = "https://${address}/health";
            tls_server_name = linkS3.hostname;
            header.Host = lib.singleton linkS3.hostname;
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
    garage-web = {
      mode = "external";
      unit = "garage";
      definition = rec {
        name = "garage-web";
        address = depot.reflection.interfaces.primary.addrPublic;
        inherit (linkWeb) port;
        checks = [
          {
            name = "Frontend";
            id = "service:garage-web:frontend";
            interval = "60s";
            http = "https://${address}/.internal-api/garage/health";
            tls_server_name = "healthcheck.${linkWeb.hostname}";
            header.Host = lib.singleton "healthcheck.${linkWeb.hostname}";
          }
          {
            name = "Garage Node";
            id = "service:garage-web:node";
            interval = "5s";
            http = "${config.links.garageMetrics.url}/health";
          }
        ];
      };
    };
  };
}
