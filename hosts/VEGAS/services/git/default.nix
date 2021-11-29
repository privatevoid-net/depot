{ config, lib, tools, ... }:
with tools.nginx;
let
  inherit (tools.meta) domain;
in
{
  reservePortsFor = [ "gitea" ];

  age.secrets = {
    giteaDBPassword = {
      file = ../../../../secrets/gitea-db-credentials.age;
      owner = "git";
      group = "gitea";
      mode = "0400";
    };
  };

  services.nginx.virtualHosts = mappers.mapSubdomains {
    git = vhosts.proxy "http://127.0.0.1:${config.portsStr.gitea}";
  };

  services.gitea = {
    enable = true;
    appName = "Private Void Gitea";
    httpPort = config.ports.gitea;
    domain = "git";
    rootUrl = "https://git.${domain}";
    disableRegistration = true;
    # TODO: re-enable securely
    ssh.enable = false;
    user = "git";
    log.level = "Warn";
    
    database = {
      createDatabase = false;
      type = "postgres";
      host = "127.0.0.1";
      port = 5432;
      name = "gitea";
      user = "gitea";
      passwordFile = config.age.secrets.giteaDBPassword.path;
    };

    # TODO: integrate branding content (css, images) into system closure
    settings.ui = { 
      DEFAULT_THEME = "void";
      THEMES = "void";
    };
  };

  users.users.git = {
    description = "Git Service";
    home = config.services.gitea.stateDir;
    useDefaultShell = true;
    group = "gitea";
    isSystemUser = true;
  };
}
