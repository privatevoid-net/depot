{ config, depot, lib, pkgs, ... }:
with lib;

{
  options = {
    tested.requiredChecks = mkOption {
      type = with types; listOf str;
      description = "Flake checks to perform.";
      default = [];
    };
  };
  config.system.extraDependencies = map (name: depot.checks.${name}) config.tested.requiredChecks;
}
