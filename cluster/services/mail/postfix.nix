{ config, depot, ... }:
let
  inherit (depot.lib.meta) domain;
  certDir = config.security.acme.certs."mail.${domain}".directory;

  receivePolicy = [ "permit_sasl_authenticated" "permit_mynetworks" "reject_unauth_destination" ];
  spamPolicy = [ "reject_sender_login_mismatch" "permit_sasl_authenticated" "pcre:${./known-spam-domains}" ];

  dkimSocket = builtins.replaceStrings ["local:"] ["unix:"] config.services.opendkim.socket;
  lmtpSocket = "lmtp:unix:/run/dovecot2/lmtp";
  postfixLdapMailboxes = "ldap:${config.age.secrets."postfix-ldap-mailboxes.cf".path}";

  inherit (config.reflection) interfaces;
in
{
  age.secrets."postfix-ldap-mailboxes.cf" = {
    file = ../../../secrets/postfix-ldap-mailboxes.age;
    owner = "postfix";
    group = "postfix";
    mode = "0400";
  };

  networking.firewall.allowedTCPPorts = [ 25 465 587 ];

  services.postfix = {
    enable = true;
    enableSubmission = true;
    enableSubmissions = true;
    setSendmail = true;
    aliasFiles.genericAliases = ./generic-aliases;

    settings.main = {
      myhostname = "mx.${domain}";
      myorigin = domain;
      mydomain = domain;
      inet_interfaces = [
        "localhost"
        interfaces.primary.addr
        interfaces.vstub.addr
      ];

      # TODO: un-hardcode
      mynetworks = [
        "localhost"
        "${interfaces.vstub.addr}/32"
        "10.10.0.0/16"
        "10.100.0.0/16"
      ];

      recipient_delimiter = "+";

      smtpd_tls_chain_files = [ "${certDir}/full.pem" ];

      disable_vrfy_command = true;

      # authorization policies
      smtpd_recipient_restrictions = receivePolicy;

      smtpd_relay_restrictions = receivePolicy;
      smtpd_sender_restrictions = spamPolicy;

      smtpd_sender_login_maps = postfixLdapMailboxes;

      # authentication
      # TODO: review these options
      smtpd_sasl_auth_enable = true;
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "/run/dovecot2/auth";
      smtpd_sasl_local_domain = domain;
      smtpd_sasl_security_options = "noanonymous";
      smtpd_sasl_tls_security_options = "noanonymous";
      smtpd_sasl_authenticated_header = true;
      broken_sasl_auth_clients = false;

      smtpd_milters = dkimSocket;
      non_smtpd_milters = dkimSocket;

      # delivery
      virtual_mailbox_domains = [ domain "max.admin.${domain}" "schizo.cooking" ];
      virtual_transport = lmtpSocket;
      mailbox_transport = lmtpSocket;
      virtual_mailbox_maps = postfixLdapMailboxes;
      virtual_alias_maps = [
        postfixLdapMailboxes
        "regexp:${./virtual-mail-domain-aliases}"
        "hash:/var/lib/postfix/conf/genericAliases"
      ];
    };
  };

  systemd.services.postfix = {
    after = [ "network-online.target" "network-addresses-${interfaces.primary.link}.service" "network-addresses-vstub.service" ];
    wants = [ "network-online.target" ];
  };
  systemd.services.postfix-setup = {
    after = [ "network-online.target" "network-addresses-${interfaces.primary.link}.service" "network-addresses-vstub.service" ];
    wants = [ "network-online.target" ];
  };

  services.fail2ban.jails.postfix.settings = {
    mode = "extra";
    findtime = "43200";
  };
}
