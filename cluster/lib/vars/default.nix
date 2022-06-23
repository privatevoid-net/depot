{ lib, ... }:
with lib;
{
  options.vars = mkOption {
    description = "Miscellaneous variables.";
    type = types.attrs;
    default = {};
  };
}
