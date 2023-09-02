{ config, inputs, lib, self, withSystem, ... }:

let
  inherit (lib) const mapAttrs;
in

{
  lib.summon = name: f: let
    lift = config;
    hour = config.hours.${name};
  in withSystem hour.system ({ config, inputs', self', ... }: f {
    depot = self // self' // lift // config // {
      inputs = mapAttrs (name: const (inputs.${name} // inputs'.${name})) inputs;
      # peer into the Watchman's Glass
      reflection = hour;
    };
  });
}
