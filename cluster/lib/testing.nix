{ lib, ... }:

{
  options = {
    simulacrum = lib.mkOption {
      description = "Whether we are in the Simulacrum.";
      type = lib.types.bool;
      default = false;
    };
    testConfig = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
    };
  };
}
