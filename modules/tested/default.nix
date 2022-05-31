{ config, inputs, lib, pkgs, ... }:
with lib;

{
  options = {
    tested.requiredChecks = mkOption {
      type = with types; listOf str;
      description = "Flake checks to perform.";
      default = [];
    };
  };
  config.system.extraDependencies = map (name: inputs.self.checks.${pkgs.system}.${name}) config.tested.requiredChecks;
}
