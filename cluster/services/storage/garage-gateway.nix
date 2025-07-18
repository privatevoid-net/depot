{ config, cluster, depot, lib, ... }:

let
  linkS3 = cluster.config.hostLinks.${config.networking.hostName}.garageS3;
  linkWeb = cluster.config.hostLinks.${config.networking.hostName}.garageWeb;
in

{
  links.garageMetrics.protocol = "http";

  services.garage.settings.admin.api_bind_addr = config.links.garageMetrics.tuple;

  consul.services = {
    garage = {
      mode = "external";
      definition = {
        name = "garage";
        address = linkS3.ipv4;
        inherit (linkS3) port;
        checks = [
          {
            name = "Garage Node";
            id = "service:garage:node";
            interval = "5s";
            http = "${config.links.garageMetrics.url}/health";
          }
        ];
        tags = let
          inherit (config.services.garage) package;
          versionTag = if lib.versionOlder package.version "1"
            then lib.versions.majorMinor package.version
            else lib.versions.major package.version;
        in [ "v${versionTag}" ];
      };
    };
    garage-web = {
      mode = "external";
      unit = "garage";
      definition = {
        name = "garage-web";
        address = linkWeb.ipv4;
        inherit (linkWeb) port;
        checks = [
          {
            name = "Garage Service Status";
            id = "service:garage-web:garage";
            alias_service = "garage";
          }
        ];
      };
    };
  };
}
