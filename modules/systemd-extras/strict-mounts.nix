{ lib, ... }:

with lib;
{
  options.systemd.services = mkOption {
    type = with types; attrsOf (submodule ({ config, ... }: {
      options.strictMounts = mkOption {
        description = "Mount points which this service strictly depends on. What that means is up to other modules.";
        type = with types; listOf path;
        default = [];
      };
      config = mkIf (config.strictMounts != []) {
        unitConfig.RequiresMountsFor = config.strictMounts;
      };
    }));
  };
}
