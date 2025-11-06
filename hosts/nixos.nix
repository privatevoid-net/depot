{ config, lib, withSystem, ... }:

let
  inherit (lib) mapAttrs nixosSystem;
  inherit (config) gods;

  mkNixOS = name: host: nixosSystem {
    specialArgs = config.lib.summon host.system lib.id;
    modules = [
      host.nixos
      (withSystem host.system ({ config, pkgs, ... }: {
        nixpkgs.pkgs = assert pkgs.stdenv.buildPlatform == pkgs.stdenv.hostPlatform; pkgs // {
          __splicedPackages = pkgs.__splicedPackages // config.shadows;
        } // config.shadows;
      }))
    ] ++ config.cluster.config.out.injectNixosConfig name;
  };
in {
  flake.nixosConfigurations = mapAttrs mkNixOS (gods.fromLight // gods.fromFlesh);
}
