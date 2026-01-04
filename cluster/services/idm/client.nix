{ cluster, config, lib, pkgs, utils, ... }:

let
  frontendLink = cluster.config.links.idm;
  inherit (cluster.config.services.idm.secrets) serviceAccountCredentials;
in

{
  systemd.services.kanidm-unixd = {
    serviceConfig.BindReadOnlyPaths = [ serviceAccountCredentials.path ];
    environment.KANIDM_SERVICE_ACCOUNT_TOKEN_PATH = serviceAccountCredentials.path;
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
      #!${pkgs.runtimeShell}
      exec ${config.services.kanidm.package}/bin/kanidm_ssh_authorizedkeys "$@"
    '';
  };

  services.openssh = {
    authorizedKeysCommand = "/etc/ssh/authorized_keys_command_kanidm";
    authorizedKeysCommandUser = "nobody";
  };

  security = {
    pam.services.sudo = { config, ... }: {
      rules.auth.rssh = {
        enable = lib.mkForce true;
        order = config.rules.auth.unix.order - 10;
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
      ln -s ${config.services.kanidm.package}/bin/kanidm $out/bin/idm
      mkdir -p $out/share/bash-completion/completions
      cat >$out/share/bash-completion/completions/idm.bash <<EOF
      source ${config.services.kanidm.package}/share/bash-completion/completions/kanidm.bash
      complete -F _kanidm -o bashdefault -o default idm
      EOF
    '';
  in [ idmAlias ];

  # i32 bug https://github.com/nix-community/nsncd/issues/6
  services.nscd.enableNsncd = false;
}
