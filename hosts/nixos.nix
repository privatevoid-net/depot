{ config, lib, withSystem, ... }:

let
  inherit (lib) mapAttrs nixosSystem;
  inherit (config) gods;

  mkNixOS = name: host: nixosSystem {
    specialArgs = config.lib.summon name lib.id;
    modules = [
      host.nixos
      (withSystem host.system ({ pkgs, ... }: {
        nixpkgs = { inherit pkgs; };
      }))
    ] ++ config.cluster.config.out.injectNixosConfig name;
  };
in {
  flake.nixosConfigurations = mapAttrs mkNixOS (gods.fromLight // gods.fromFlesh);
}
