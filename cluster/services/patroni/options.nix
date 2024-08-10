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
              type = enum [ "pgpass" "envFile" ];
              default = "pgpass";
            };
          };
        };
      }));
    };
  };
}
