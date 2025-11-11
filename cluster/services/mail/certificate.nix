{ config, depot, lib, ... }:

{
  security.acme.certs."mail.${depot.lib.meta.domain}" = {
    dnsProvider = "exec";
    webroot = lib.mkForce null;
    extraDomainNames = map (x: "${x}.${depot.lib.meta.domain}") [
      "mx"
      "imap"
      "smtp"
    ];
    reloadServices =
      lib.optional config.services.postfix.enable "postfix.service" ++
      lib.optional config.services.dovecot2.enable "dovecot.service";
  };
}
