{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.idm.tmpfiles;

  rulesFile = pkgs.writeText "idm-tmpfiles.conf" (concatStringsSep "\n" cfg.rules);
in

{
  options.idm.tmpfiles.rules = mkOption {
    description = "systemd-tmpfiles rules to run after IDM is ready.";
    type = with types; listOf str;
    default = [];
  };

  config = mkIf (cfg.rules != []) {
    systemd.services.idm-tmpfiles = {
      description = "Set up tmpfiles after IDM";
      requires = [ "idm-nss-ready.service" "nss-user-lookup.target" ];
      after = [ "idm-nss-ready.service" "nss-user-lookup.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${config.systemd.package}/bin/systemd-tmpfiles --create --remove ${rulesFile}";
        Type = "oneshot";
      };
    };
  };
}
