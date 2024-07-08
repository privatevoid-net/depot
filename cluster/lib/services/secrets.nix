{ lib, name, ... }:

let
  serviceName = name;
in

{
  options.secrets = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule ({ config, name, ... }: {
      options = {
        shared = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether this secret should be the same on all nodes.";
        };

        nodes = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
        };

        generate = lib.mkOption {
          type = with lib.types; nullOr (functionTo str);
          description = "Command used to generate this secret.";
          default = null;
        };

        path = lib.mkOption {
          type = lib.types.path;
          default = "/run/agenix/cluster-${serviceName}-${name}";
        };

        mode = lib.mkOption {
          type = lib.types.str;
          default = "0400";
        };

        owner = lib.mkOption {
          type = lib.types.str;
          default = "root";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "root";
        };

        services = lib.mkOption {
          type = with lib.types; listOf str;
          description = "Services to restart when this secret changes.";
          default = [];
        };
      };
    }));
    default = {};
  };
}
