{ config, lib, ... }:

let
  timeTravel = rev: builtins.getFlake "github:privatevoid-net/depot/${rev}";

in

{
  _module.args = { inherit timeTravel; };
  perSystem = { system, ... }: {
    _module.args.timeTravel' = rev: let
      flake = timeTravel rev;
      flake' = config.perInput system flake;
    in flake' // {
      inputs = lib.mapAttrs (_: input: config.perInput system input) flake.inputs;
    };
  };
}
