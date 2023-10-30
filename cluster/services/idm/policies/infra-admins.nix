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

  idm.tmpfiles.rules = [
    "a+ /run/log/journal - - - - d:group:infra_admins:r-x,group:infra_admins:r-x"
    "a+ /run/log/journal/%m - - - - d:group:infra_admins:r-x,group:infra_admins:r-x"
    "a+ /run/log/journal/%m/*.journal* - - - - group:infra_admins:r--"
  ];
}
