{ config, pkgs, lib, modulesPath, aspect, inputs, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
    inputs.agenix.nixosModules.age
  ]
  ++ (import ../../users "server").groups.admin
  ++ aspect.sets.server
  ++ (with aspect.modules; [ ]);

  age.secrets = {
    giteaDBPassword = {
      file = ../../secrets/gitea-db-credentials.age;
      owner = "git";
      group = "gitea";
      mode = "0400";
    };
  };

  networking.hostName = "git";
  networking.firewall.enable = false;

  nix.trustedUsers = [ "root" "@wheel" ];

  security.sudo.wheelNeedsPassword = false;
  
  services.gitea = {
    enable = true;
    appName = "Private Void Gitea";
    domain = "git";
    rootUrl = "https://git.privatevoid.net";
    disableRegistration = true;
    ssh.enable = true;
    user = "git";
    log.level = "Warn";
    
    database = {
      createDatabase = false;
      type = "postgres";
      host = "10.1.0.1";
      port = 5432;
      name = "gitea";
      user = "gitea";
      passwordFile = config.age.secrets.giteaDBPassword.path;
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
