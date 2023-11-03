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
      garage = [ "prophet" "VEGAS" ];
      garageConfig = [ "prophet" "VEGAS" ];
      garageInternal = [ "VEGAS" ];
      garageExternal = [ "prophet" ];
    };
    nixos = {
      external = [ ./external.nix ];
      heresy = [ ./heresy.nix ];
      garage = [
        ./garage.nix
        ./garage-options.nix
        ./garage-layout.nix
      ];
      garageConfig = [
        ./garage-gateway.nix
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

  links.garageS3 = {
    hostname = "garage.${depot.lib.meta.domain}";
    port = 443;
    protocol = "https";
    url = with config.links.garageS3; lib.mkForce "${protocol}://${hostname}";
  };

  hostLinks = lib.genAttrs config.services.storage.nodes.garage (name: {
    garageRpc = {
      ipv4 = meshIpForNode name;
    };
    garageS3 = {
      protocol = "http";
      ipv4 = meshIpForNode name;
    };
  });

  garage = {
    keys.storage-prophet = {};
    buckets.storage-prophet = {
      allow.storage-prophet = [ "read" "write" ];
    };
  };

  dns.records.garage.consulService = "garage";
}
