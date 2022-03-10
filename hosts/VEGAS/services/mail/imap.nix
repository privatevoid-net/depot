{ config, lib, pkgs, tools, ... }:
let
  inherit (tools.identity) ldap;
  inherit (tools.meta) domain;

  postfixCfg = config.services.postfix;

  # TODO: switch to proper certdir
  certDir = config.security.acme.certs."mail.${domain}".directory;

  # TODO: check how this thing does lookups, apply bind dn
  ldapConfig = with ldap.accounts; pkgs.writeText "dovecot-ldap.conf.ext" ''
    uris = ${ldap.server.url}

    auth_bind = yes
    auth_bind_userdn = ${uidAttribute}=%n,${userSearchBase}
    base = ${userSearchBase}
    pass_filter = (uid=%n)
    pass_attrs = uid=user
  '';
in {
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

    sieveScripts.after = ./sieve;

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
  services.fail2ban.jails.dovecot = ''
    enabled = true
  '';
}
