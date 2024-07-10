{ lib, ... }:

with lib;
{
  options.systemd.services = mkOption {
    type = with types; attrsOf (submodule ({ config, name, ... }: {
      options.chant = {
        enable = mkEnableOption "listening for a waking chant";
      };
      config = lib.mkIf config.chant.enable {
        serviceConfig = {
          Type = "oneshot";
          LoadCredential = [ "chantPayload:/run/chant/${name}" ];
        };
        environment.CHANT_PAYLOAD = "%d/chantPayload";
      };
    }));
  };
}
