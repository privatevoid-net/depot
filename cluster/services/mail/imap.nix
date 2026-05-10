{ config, pkgs, depot, ... }:
let
  inherit (depot.lib.identity) ldap;
  inherit (depot.lib.meta) domain;

  postfixCfg = config.services.postfix;

  # TODO: switch to proper certdir
  certDir = config.security.acme.certs."mail.${domain}".directory;

  # TODO: check how this thing does lookups, apply bind dn

  ldapConfigBase = with ldap.accounts; pkgs.writeText "dovecot-ldap.conf.ext" ''
    uris = ${ldap.server.url}

    auth_bind = yes
    auth_bind_userdn = ${uidAttribute}=%n,${userSearchBase}
    base = ${userSearchBase}
    pass_filter = (&(objectClass=person)(${uidAttribute}=%n))
    pass_attrs = uid=user
    dn = dn=token
    dnpass = @DOVECOT2_LDAP_DNPASS@
  '';

  ldapConfig = "/run/dovecot2/dovecot-ldap.conf.ext";

  writeLdapConfig = pkgs.writeShellScriptBin "write-ldap-config" ''
    cp ${ldapConfigBase} ${ldapConfig}
    chmod 600 ${ldapConfig}
    ${pkgs.replace-secret}/bin/replace-secret '@DOVECOT2_LDAP_DNPASS@' "${config.age.secrets.dovecotLdapToken.path}" ${ldapConfig}
    chmod 400 ${ldapConfig}
  '';
in {

  age.secrets.dovecotLdapToken.file = ../../../secrets/dovecot-ldap-token.age;

  networking.firewall.allowedTCPPorts = [ 143 993 ];

  # who came up with this shit?
  environment.systemPackages = [
    pkgs.dovecot_pigeonhole_0_5
  ];

  services.dovecot2 = {
    enable = true;
    enablePAM = false;
    mailUser = "vmail";
    mailGroup = "vmail";
    mailPlugins.perProtocol.lmtp.enable = [ "sieve" ];

    settings = {
      protocols = [ "imap" "lmtp" ];
      mail_location = "maildir:/var/spool/mail/%u";
      ssl_cert = "<${certDir}/fullchain.pem";
      ssl_key = "<${certDir}/key.pem";
      auth_username_format = "%n";
      namespace = {
        inbox = true;
        separator = "/";
      };
      userdb = {
        driver = "static";
        args = [
          "allow_all_users=yes"
          "uid=${config.services.dovecot2.mailUser}"
          "gid=${config.services.dovecot2.mailGroup}"
          "home=/var/mail/virtual/%d/%n"
        ];
      };

      passdb = {
        driver = "ldap";
        args = ldapConfig;
      };
      "service auth" = {
        "unix_listener auth" = {
          mode = "0660";
          inherit (postfixCfg) user group;
        };
      };
    };

    sieve = {
      extensions = [
        "fileinto"
      ];
      scripts.before = ./sieve/spam.sieve;
    };
  };

  systemd.services.dovecot.serviceConfig.ExecStartPre = [ "${writeLdapConfig}/bin/write-ldap-config" ];

  services.fail2ban.jails.dovecot = {};
}
