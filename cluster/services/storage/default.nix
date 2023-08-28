{ config, lib, ... }:

let
  meshIpForNode = name: config.vars.mesh.${name}.meshIp;
in

{
  services.storage = {
    nodes = {
      external = [ "prophet" ];
      heresy = [ "VEGAS" ];
      garage = [ "checkmate" "prophet" "VEGAS" ];
      garageInternal = [ "VEGAS" ];
      garageExternal = [ "checkmate" "prophet" ];
    };
    nixos = {
      external = [ ./external.nix ];
      heresy = [ ./heresy.nix ];
      garage = [
        ./garage.nix
        ./garage-layout.nix
      ];
      garageInternal = [ ./garage-internal.nix ];
      garageExternal = [ ./garage-external.nix ];
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
}
