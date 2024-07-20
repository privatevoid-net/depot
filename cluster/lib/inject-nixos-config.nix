{ config, lib, ... }:
with lib;

{
  options.out = mkOption {
    description = "Output functions.";
    type = with types; lazyAttrsOf (functionTo raw);
    default = const [];
  };
}
