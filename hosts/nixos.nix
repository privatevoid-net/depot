{ config, lib, withSystem, ... }:

let
  inherit (lib) mapAttrs nixosSystem;
  inherit (config) gods;

  nixpkgsInstances = lib.genAttrs config.systems (system: withSystem system ({ config, pkgs, ... }: pkgs));

  collectModules = name: host: [
    host.nixos
    {
      nixpkgs.hostPlatform = lib.mkDefault host.system;
      nixpkgs.instances = nixpkgsInstances;
    }
  ] ++ config.cluster.config.out.injectNixosConfig name;

  mkNixOS = name: host: nixosSystem {
    inherit (config.lib.hours) specialArgs;
    modules = collectModules name host;
  };
in {
  flake.nixosConfigurations = mapAttrs mkNixOS gods.fromBlood;

  clan.machines = mapAttrs (name: hour: { imports = collectModules name hour; }) (gods.fromLight // gods.fromFlesh);
}
