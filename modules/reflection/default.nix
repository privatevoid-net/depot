{ config, depot, lib, pkgs, ... }:

{
  options.reflection = lib.mkOption {
    description = "Peer into the Watchman's Glass.";
    type = lib.types.raw;
    readOnly = true;
    default = depot.hours.${config.networking.hostName};
  };

  config._module.args.depot' = let
    inherit (pkgs.stdenv.hostPlatform) system;
  in {
    packages = depot.packages.${system};
    inputs = lib.mapAttrs (_: input: {
      packages = input.packages.${system};
    }) depot.inputs;
  };
}
