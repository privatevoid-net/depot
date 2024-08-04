{ lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) attrsOf listOf submodule str;
in

{
  options.incandescence = {
    providers = mkOption {
      type = attrsOf (submodule ({ name, ... }: {
        options = {
          objects = mkOption {
            type = attrsOf (listOf str);
            default = { };
          };
        };
      }));
      default = { };
    };
  };
}
