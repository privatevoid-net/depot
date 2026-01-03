{ config, lib, withSystem, ... }:

let
  inherit (lib) mapAttrs nixosSystem;
  inherit (config) gods;

  mkNixOS = name: host: nixosSystem {
    inherit (config.lib.hours) specialArgs;
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
