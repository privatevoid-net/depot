{ lib, ... }:

let
  inherit (lib) mkEnableOption mkOption;
  inherit (lib.types) attrsOf functionTo ints listOf nullOr package submodule str;
in

{
  options.services.incandescence = {
    providers = mkOption {
      type = attrsOf (submodule ({ name, ... }: {
        options = {
          locksmith = mkEnableOption "Locksmith integration";

          wantedBy = mkOption {
            type = listOf str;
          };

          partOf = mkOption {
            type = listOf str;
          };

          wants = mkOption {
            type = listOf str;
            default = [ ];
          };

          after = mkOption {
            type = listOf str;
            default = [ ];
          };

          packages = mkOption {
            type = listOf package;
            default = [ ];
          };

          formulae = mkOption {
            type = attrsOf (submodule ({ ... }: {
              options = {
                deps = mkOption {
                  type = listOf str;
                  default = [ ];
                };

                create = mkOption {
                  type = functionTo str;
                };

                change = mkOption {
                  type = nullOr (functionTo str);
                  default = null;
                };

                destroy = mkOption {
                  type = str;
                };

                destroyAfterDays = mkOption {
                  type = ints.unsigned;
                  default = 0;
                };
              };
            }));
            default = { };
          };
        };
      }));
      default = { };
    };
  };
}
