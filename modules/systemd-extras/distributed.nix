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
        registerServices = mkOption {
          description = "Consul services to register when this service gets started.";
          type = with types; listOf str;
          default = if config.distributed.registerService == null then [ ] else [ config.distributed.registerService ];
        };
      };
    }));
  };
}
