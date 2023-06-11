{ lib, ... }:

{
  services.kanidm.unixSettings = {
    pam_allowed_login_groups = [
      "infra_admins"
    ];
  };

  security.sudo.extraRules = lib.singleton {
    groups = [ "infra_admins" ];
    commands = lib.singleton {
      command = "ALL";
      options = [ "SETENV" ];
    };
  };
}
