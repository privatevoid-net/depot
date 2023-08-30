{ depot, ... }:
{
  imports = [
    ./imap.nix
    ./opendkim.nix
    ./postfix.nix
    ./saslauthd.nix
  ];
  services.nginx.virtualHosts."mail.${depot.lib.meta.domain}" = {
    enableACME = true;
    locations."/".return = "204";
  };
  security.acme.certs."mail.${depot.lib.meta.domain}".extraDomainNames = map
  (x: "${x}.${depot.lib.meta.domain}") [
    "mx"
    "imap"
    "smtp"
  ];
}
