{ config, depot, lib, ... }:

let
  meshIpForNode = name: config.vars.mesh.${name}.meshIp;
in

{
  imports = [
    ./options.nix
  ];

  services.storage = {
    nodes = {
      external = [ "prophet" ];
      heresy = [ "VEGAS" ];
      garage = [ "grail" "prophet" "VEGAS" ];
      garageConfig = [ "grail" "prophet" "VEGAS" ];
      garageInternal = [ "VEGAS" ];
      garageExternal = [ "grail" "prophet" ];
    };
    nixos = {
      external = [
        ./external.nix
        ./s3ql-upgrades.nix
      ];
      heresy = [
        ./heresy.nix
        ./s3ql-upgrades.nix
      ];
      garage = [
        ./garage.nix
        ./garage-options.nix
        ./garage-layout.nix
      ];
      garageConfig = [
        ./garage-gateway.nix
        ./garage-metrics.nix
        {
          services.garage = {
            inherit (config.garage) buckets keys;
          };
        }
      ];
      garageInternal = [ ./garage-internal.nix ];
      garageExternal = [ ./garage-external.nix ];
    };
  };

  links = {
    garageS3 = {
      hostname = "garage.${depot.lib.meta.domain}";
      port = 443;
      protocol = "https";
      url = with config.links.garageS3; lib.mkForce "${protocol}://${hostname}";
    };

    garageWeb = {
      hostname = "web.garage.${depot.lib.meta.domain}";
      port = 443;
      protocol = "https";
      url = with config.links.garageWeb; lib.mkForce "${protocol}://${hostname}";
    };
  };

  hostLinks = lib.genAttrs config.services.storage.nodes.garage (name: {
    garageRpc = {
      ipv4 = meshIpForNode name;
    };
    garageS3 = {
      protocol = "http";
      ipv4 = meshIpForNode name;
    };
    garageWeb = {
      protocol = "http";
      ipv4 = meshIpForNode name;
    };
  });

  monitoring.blackbox.targets.garage = {
    address = "https://content-delivery.web.garage.${depot.lib.meta.domain}/";
    module = "https2xx";
  };

  garage = {
    keys.storage-prophet = {};
    buckets.storage-prophet = {
      allow.storage-prophet = [ "read" "write" ];
    };
  };

  ways = {
    garage = {
      consulService = "garage";
      extras.extraConfig = ''
        client_max_body_size 4G;
      '';
    };
    "web.garage" = {
      consulService = "garage-web";
      wildcard = true;
      extras.locations."/".extraConfig = ''
        proxy_set_header Host "$1.${config.links.garageWeb.hostname}";
      '';
    };
  };
}
