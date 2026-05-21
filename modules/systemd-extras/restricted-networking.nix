{ config, lib, ... }@lift:

with lib;
{
  options.systemd = {
    restrictedNetworking = {
      internalNetworks = mkOption {
        type = with types; listOf str;
      };
      trustedInternalNetworks = mkOption {
        type = with types; listOf str;
      };
      trustedPublicNetworks = mkOption {
        type = with types; listOf str;
      };
    };
    services = mkOption {
      type = with types; attrsOf (submodule ({ config, name, ... }: {
        options.restrictedNetworking = {
          enable = mkEnableOption "restricted networking";
          mode = mkOption {
            type = types.enum [ "untrusted" "public" "trustedPublic" "internal" "trustedInternal" "trusted" ];
            default = [];
          };
        };
        config = lib.mkIf config.restrictedNetworking.enable {
          serviceConfig = let
            cfg = lift.config.systemd.restrictedNetworking;
          in {
            untrusted = {
              IPAddressDeny = cfg.internalNetworks ++ cfg.trustedInternalNetworks ++ cfg.trustedPublicNetworks;
            };
            public = {
              IPAddressDeny = cfg.internalNetworks ++ cfg.trustedInternalNetworks;
            };
            trustedPublic = {
              IPAddressDeny = [ "any" ];
              IPAddressAllow = cfg.trustedPublicNetworks;
            };
            internal = {
              IPAddressDeny = [ "any" ];
              IPAddressAllow = cfg.internalNetworks ++ cfg.trustedInternalNetworks;
            };
            trustedInternal = {
              IPAddressDeny = [ "any" ];
              IPAddressAllow = cfg.trustedInternalNetworks;
            };
            trusted = {
              IPAddressDeny = [ "any" ];
              IPAddressAllow = cfg.trustedInternalNetworks ++ cfg.trustedPublicNetworks;
            };
          }.${config.restrictedNetworking.mode};
        };
      }));
    };
  };

  config.systemd.restrictedNetworking = {
    internalNetworks = [
      "10.0.0.0/8"
			"172.16.0.0/12"
			"192.168.0.0/16"
			"169.254.0.0/16"
			"fe80::/10"
			"fd00::/7"
    ];
    trustedInternalNetworks = [
      "127.0.0.1/8"
      "::1/128"
    ];
    trustedPublicNetworks = [];
  };
}
