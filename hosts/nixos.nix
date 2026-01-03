{ config, lib, withSystem, ... }:

let
  inherit (lib) mapAttrs nixosSystem;
  inherit (config) gods;

  collectModules = name: host: [
    host.nixos
    (withSystem host.system ({ config, pkgs, ... }: {
      nixpkgs.pkgs = assert pkgs.stdenv.buildPlatform == pkgs.stdenv.hostPlatform; pkgs // {
        __splicedPackages = pkgs.__splicedPackages // config.shadows;
      } // config.shadows;
    }))
  ] ++ config.cluster.config.out.injectNixosConfig name;

  mkNixOS = name: host: nixosSystem {
    inherit (config.lib.hours) specialArgs;
    modules = collectModules name host;
  };
in {
  flake.nixosConfigurations = mapAttrs mkNixOS gods.fromFlesh;

  clan.machines = mapAttrs (name: hour: { imports = collectModules name hour; }) gods.fromLight;
}
