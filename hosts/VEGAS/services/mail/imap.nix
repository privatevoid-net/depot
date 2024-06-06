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

  age.secrets.dovecotLdapToken.file = ../../../../secrets/dovecot-ldap-token.age;

  networking.firewall.allowedTCPPorts = [ 143 993 ];

  services.dovecot2 = {
    enable = true;
    enableLmtp = true;
    enableImap = true;
    enablePAM = false;
    mailUser = "vmail";
    mailGroup = "vmail";
    sslServerCert = "${certDir}/fullchain.pem";
    sslServerKey = "${certDir}/key.pem";

    modules = [ pkgs.dovecot_pigeonhole ];

    sieve = {
      extensions = [
        "variables"
        "envelope"
        "fileinto"
        "subaddress"
        "mailbox"
      ];
      scripts.after = ./sieve;
    };

    extraConfig = with config.services.dovecot2; ''
      auth_username_format = %n

      namespace {
        inbox = yes
        separator = /
      }
      userdb {
        driver = static
        args = allow_all_users=yes uid=${mailUser} gid=${mailUser} home=/var/mail/virtual/%d/%n
      }
      passdb {
        driver = ldap
        args = ${ldapConfig}
      }

      service auth {
        unix_listener auth {
          mode = 0660
          user = ${postfixCfg.user}
          group = ${postfixCfg.group}
        }
      }

      auth_mechanisms = plain login
    '';
  };

  systemd.services.dovecot2.serviceConfig.ExecStartPre = [ "${writeLdapConfig}/bin/write-ldap-config" ];

  services.fail2ban.jails.dovecot = {};
}
