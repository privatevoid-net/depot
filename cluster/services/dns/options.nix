{ depot, lib, ... }:

with lib;

let
  recordType = types.submodule ({ config, name, ... }: {
    options = {
      root = mkOption {
        type = types.str;
        default = depot.lib.meta.domain;
      };
      consulServicesRoot = mkOption {
        type = types.str;
        default = "service.eu-central.sd-magic.${depot.lib.meta.domain}";
      };
      name = mkOption {
        type = types.str;
        default = name;
      };

      type = mkOption {
        type = types.enum [ "A" "CNAME" "AAAA" "NS" "MX" "SOA" ];
        default = "A";
      };
      target = mkOption {
        type = with types; listOf str;
      };
      ttl = mkOption {
        type = types.ints.unsigned;
        default = 86400;
      };

      consulService = mkOption {
        type = with types; nullOr str;
        default = null;
      };
      rewriteTarget = mkOption {
        type = with types; nullOr str;
        default = null;
      };
    };
    config = {
      rewriteTarget = mkIf (config.consulService != null) "${config.consulService}.${config.consulServicesRoot}";
    };
  });
in

{
  options.dns = {
    records = mkOption {
      type = with types; attrsOf recordType;
      default = {};
    };
  };
}
