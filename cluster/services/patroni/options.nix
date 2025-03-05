{ lib, ... }:

let
  inherit (lib) mkOption;
  inherit (lib.types) attrsOf enum listOf submodule str;
in

{
  options.patroni = {
    databases = mkOption {
      type = attrsOf (submodule ({ name, ... }: {
        options = {
          owner = mkOption {
            type = str;
            default = name;
          };
        };
      }));
      default = {};
    };
    users = mkOption {
      type = attrsOf (submodule ({ ... }: {
        options = {
          locksmith = {
            nodes = mkOption {
              type = listOf str;
              default = [];
            };
            format = mkOption {
              type = enum [ "pgpass" "envFile" "raw" ];
              default = "pgpass";
            };
            owner = mkOption {
              type = str;
              default = "root";
            };
            group = mkOption {
              type = str;
              default = "root";
            };
            mode = mkOption {
              type = str;
              default = "0400";
            };
          };
        };
      }));
      default = {};
    };
  };
}
