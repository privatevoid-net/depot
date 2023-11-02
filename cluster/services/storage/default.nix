{ config, lib, ... }:

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
      garage = [ "checkmate" "prophet" "VEGAS" ];
      garageInternal = [ "VEGAS" ];
      garageExternal = [ "checkmate" "prophet" ];
      garageLimitMemory = [ "checkmate" ];
    };
    nixos = {
      external = [ ./external.nix ];
      heresy = [ ./heresy.nix ];
      garage = [
        ./garage.nix
        ./garage-options.nix
        ./garage-layout.nix
        {
          services.garage = {
            inherit (config.garage) buckets keys;
          };
        }
      ];
      garageInternal = [ ./garage-internal.nix ];
      garageExternal = [ ./garage-external.nix ];
      garageLimitMemory = [ ./garage-limit-memory.nix ];
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
  });

  garage = {
    keys.storage-prophet = {};
    buckets.storage-prophet = {
      allow.storage-prophet = [ "read" "write" ];
    };
  };
}
