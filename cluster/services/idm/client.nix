{ cluster, config, pkgs, utils, ... }:

let
  frontendLink = cluster.config.links.idm;
in

{
  age.secrets.idmServiceAccountCredentials.file = ./secrets/service-account-${config.networking.hostName}.age;

  systemd.services.kanidm-unixd.serviceConfig = {
    EnvironmentFile = config.age.secrets.idmServiceAccountCredentials.path;
  };

  services.kanidm = {
    enableClient = true;
    clientSettings = {
      uri = frontendLink.url;
    };
    enablePam = true;
    unixSettings = {
      default_shell = utils.toShellPath config.users.defaultUserShell;
      home_alias = "name";
      uid_attr_map = "name";
      gid_attr_map = "name";
    };
  };

  environment.etc."ssh/authorized_keys_command_kanidm" = {
    mode = "0755";
    text = ''
      #!/bin/sh
      exec ${pkgs.kanidm}/bin/kanidm_ssh_authorizedkeys "$@"
    '';
  };

  services.openssh = {
    authorizedKeysCommand = "/etc/ssh/authorized_keys_command_kanidm";
    authorizedKeysCommandUser = "nobody";
  };

  security = {
    pam.services.sudo = { config, ... }: {
      rules.auth.rssh = {
        order = config.rules.auth.unix.order - 10;
        control = "sufficient";
        modulePath = "${pkgs.pam_rssh}/lib/libpam_rssh.so";
        settings = {
          authorized_keys_command = "/etc/ssh/authorized_keys_command_kanidm";
          authorized_keys_command_user = "nobody";
        };
      };
    };

    sudo.extraConfig = ''
      Defaults env_keep+=SSH_AUTH_SOCK
    '';
  };

  environment.systemPackages = let
    idmAlias = pkgs.runCommand "kanidm-idm-alias" {} ''
      mkdir -p $out/bin
      ln -s ${pkgs.kanidm}/bin/kanidm $out/bin/idm
      mkdir -p $out/share/bash-completion/completions
      cat >$out/share/bash-completion/completions/idm.bash <<EOF
      source ${pkgs.kanidm}/share/bash-completion/completions/kanidm.bash
      complete -F _kanidm -o bashdefault -o default idm
      EOF
    '';
  in [ idmAlias ];

  # i32 bug https://github.com/nix-community/nsncd/issues/6
  services.nscd.enableNsncd = false;
}
