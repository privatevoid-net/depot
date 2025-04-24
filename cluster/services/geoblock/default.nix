{ depot, lib, ... }:

{
  services.geoblock = {
    nodes.host = lib.attrNames depot.gods.fromLight;
    nixos.host = [
      ./incoming.nix
    ];
  };
}
