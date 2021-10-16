{ config, pkgs, tools, ... }:
{
  age.secrets = {
    discourse-adminpass = {
      file = ../../../../secrets/discourse-adminpass.age;
      owner = "discourse";
      group = "discourse";
      mode = "0400";
    };
    discourse-dbpass = {
      file = ../../../../secrets/discourse-dbpass.age;
      owner = "discourse";
      group = "discourse";
      mode = "0400";
    };
  };
  services.discourse = {
    enable = true;
    nginx.enable = true;
    hostname = "forum.${tools.meta.domain}";

    plugins = with pkgs.discourse.plugins; [
      discourse-ldap-auth
    ];

    admin = {
      email = tools.meta.adminEmail;
      fullName = "Site Administrator";
      username = "admin";
      passwordFile = config.age.secrets.discourse-adminpass.path;
    };

    database = {
      host = "127.0.0.1";
      name = "forum";
      username = "forum";
      passwordFile = config.age.secrets.discourse-dbpass.path;
    };
  };
}
