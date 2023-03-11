{ config, inputs, lib, self, withSystem, ... }:

let
  inherit (lib) const mapAttrs nixosSystem;
  inherit (config) gods;

  mkSpecialArgs = system: hostName: withSystem system ({ inputs', self', ... }: {
    depot = self // self' // {
      inputs = mapAttrs (name: const (inputs.${name} // inputs'.${name})) inputs;
      inherit config;
      # peer into the Watchman's Glass
      reflection = config.hours.${hostName};
    };
    toolsets = import ../tools;
  });

  mkNixOS = name: host: nixosSystem {
    specialArgs = mkSpecialArgs host.system name;
    inherit (host) system;
    modules = [ host.nixos ../tools/inject.nix (import ../cluster/inject.nix name) ];
  };
in {
  flake.nixosConfigurations = mapAttrs mkNixOS (gods.fromLight // gods.fromFlesh);
}
