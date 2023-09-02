{ config, lib, ... }:

let
  inherit (lib) mapAttrs nixosSystem;
  inherit (config) gods;

  mkNixOS = name: host: nixosSystem {
    specialArgs = config.lib.summon name lib.id;
    inherit (host) system;
    modules = [ host.nixos ] ++ config.cluster.config.out.injectNixosConfig name;
  };
in {
  flake.nixosConfigurations = mapAttrs mkNixOS (gods.fromLight // gods.fromFlesh);
}
