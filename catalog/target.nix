{ lib, name, ... }:

{
  options = {
    description = lib.mkOption {
      type = lib.types.str;
      default = name;
    };

    actions = lib.mkOption {
      type = with lib.types; lazyAttrsOf (submodule {
        options = {
          description = lib.mkOption {
            type = lib.types.str;
            default = name;
          };
        
          command = lib.mkOption {
            type = lib.types.str;
          };

          packages = lib.mkOption {
            type = with lib.types; listOf package;
            default = [];
          };
        };
      });
      default = {};
    };
  };
}
