{ config, inputs, lib, self, withSystem, ... }:

let
  inherit (lib) const mapAttrs;
in

{
  lib.summon = system: f: let
    lift = config;
  in withSystem system ({ config, inputs', self', ... }: f {
    depot = self // self' // lift // config // {
      inputs = mapAttrs (name: const (inputs.${name} // inputs'.${name})) inputs;
    };
  });
}
