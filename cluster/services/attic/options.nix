{ lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) attrsOf listOf submodule str ints;
in

{
  options.attic = {
    tokens = mkOption {
      type = attrsOf (submodule ({ name, ... }: {
        options = {
          subject = mkOption {
            type = str;
            default = name;
          };
          validityDays = mkOption {
            type = ints.between 7 365;
            default = 30;
          };
          push = mkOption {
            type = listOf str;
            default = [];
          };
          pull = mkOption {
            type = listOf str;
            default = [];
          };
          delete = mkOption {
            type = listOf str;
            default = [];
          };
          createCache = mkOption {
            type = listOf str;
            default = [];
          };
          configureCache = mkOption {
            type = listOf str;
            default = [];
          };
          configureCacheRetention = mkOption {
            type = listOf str;
            default = [];
          };
          destroyCache = mkOption {
            type = listOf str;
            default = [];
          };
          locksmith = {
            nodes = mkOption {
              type = listOf str;
            };
          };
        };
      }));
      default = {};
    };
  };
}
