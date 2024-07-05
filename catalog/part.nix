{ lib, ... }:

{
  perSystem = {
    options.catalog = lib.mkOption {
      type = with lib.types; lazyAttrsOf (lazyAttrsOf (lazyAttrsOf (submodule ./target.nix)));
      default = {};
    };
  };
}
