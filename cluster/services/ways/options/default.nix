{ lib, ... }:

{
  options.ways = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ./way.nix);
    default = {};
  };
}
