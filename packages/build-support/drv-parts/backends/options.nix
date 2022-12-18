{ lib, ... }:
with lib;

{
  options = {
    drv-backends = mkOption {
      description = "drv-parts backends";
      type = with types; attrsOf raw;
      default = {};
    };
  };
}
