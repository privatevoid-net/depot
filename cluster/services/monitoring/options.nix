{ lib, ... }:
with lib;

{
  options.monitoring = {
    blackbox = {
      targets = mkOption {
        description = "Blackbox targets to be monitored by the cluster.";
        default = {};
        type = with types; attrsOf (submodule ({ ... }: {
          options = {
            module = mkOption {
              description = "The Blackbox module to use.";
              type = types.str;
            };
            address = mkOption {
              description = "The target's address.";
              type = types.str;
            };
          };
        }));
      };
    };
  };
}
