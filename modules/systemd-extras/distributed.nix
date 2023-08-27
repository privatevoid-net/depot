{ lib, ... }:

with lib;
{
  options.systemd.services = mkOption {
    type = with types; attrsOf (submodule ({ config, ... }: {
      options.distributed = {
        enable = mkEnableOption "distributed mode";

        replicas = mkOption {
          description = "Maximum number of replicas to run at once.";
          type = types.int;
          default = 1;
        };
        registerService = mkOption {
          description = "Consul service to register when this service gets started.";
          type = with types; nullOr str;
          default = null;
        };
      };
    }));
  };
}
