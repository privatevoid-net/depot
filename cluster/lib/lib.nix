{ config, lib, ... }:

{
  options.lib = {
    forService = lib.mkOption {
      description = "Enable these definitions for a particular service only.";
      type = lib.types.functionTo lib.types.raw;
      readOnly = true;
      default = service: lib.mkIf (!config.simulacrum || lib.any (s: s == service) config.testConfig.activeServices);
    };
  };
}
