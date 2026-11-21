{ config, pkgs, depot, ... }:
let
  inherit (depot.lib.identity) ldap;
  inherit (depot.lib.meta) domain;

  postfixCfg = config.services.postfix;

  # TODO: switch to proper certdir
  certDir = config.security.acme.certs."mail.${domain}".directory;

  ldapConfigBase = pkgs.writeText "dovecot-ldap.conf.ext" ''
    ldap_auth_dn_password = @DOVECOT2_LDAP_DNPASS@
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
    pkgs.dovecot_pigeonhole
  ];

  services.dovecot2 = {
    enable = true;
    package = pkgs.dovecot_2_4;
    enablePAM = false;

    includeFiles = [
      ldapConfig
    ];

    settings = {
      mail_uid = "vmail";
      mail_gid = "vmail";
      dovecot_config_version = "2.4.2";
      dovecot_storage_version = "2.4.0";

      protocols = [ "imap" "lmtp" ];
      mail_driver = "maildir";
      mail_path = "/var/spool/mail/%{user}";
      ssl_server = {
        cert_file = "${certDir}/fullchain.pem";
        key_file = "${certDir}/key.pem";
      };

      auth_username_format = "%{ user | username }";

      "namespace inbox" = {
        inbox = true;
        separator = "/";
      };

      "userdb static" = {
        driver = "static";
        fields = {
          allow_all_users = true;
          uid = config.services.dovecot2.settings.mail_uid;
          gid = config.services.dovecot2.settings.mail_gid;
          home = "/var/mail/virtual/%d/%n";
        };
      };

      ldap_uris = ldap.server.url;
      ldap_base = ldap.accounts.userSearchBase;
      ldap_auth_dn = "dn=token";
      "passdb ldap" = with ldap.accounts; {
        driver = "ldap";
        bind = true;
        bind_userdn = "${uidAttribute}=%{user | username},${userSearchBase}";
        filter = "(&(objectClass=person)(${uidAttribute}=%{user | username}))";
        fields = {
          user = "%{user | username}";
        };
      };

      "service auth" = {
        "unix_listener auth" = {
          mode = "0660";
          inherit (postfixCfg) user group;
        };
      };

      "protocol lmtp".mail_plugins.sieve = true;

      sieve_extensions.fileinto = true;
      "sieve_script 00spam" = {
        driver = "file";
        path = ./sieve/spam.sieve;
        type = "before";
      };
    };
  };

  systemd.services.dovecot.serviceConfig.ExecStartPre = [ "${writeLdapConfig}/bin/write-ldap-config" ];

  services.fail2ban.jails.dovecot = {};
}
