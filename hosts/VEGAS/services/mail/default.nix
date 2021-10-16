{ tools, ... }:
{
  imports = [
    ./imap.nix
    ./opendkim.nix
    ./postfix.nix
    ./saslauthd.nix
  ];
  services.nginx.virtualHosts."mail.${tools.meta.domain}" = {
    enableACME = true;
    locations."/".return = "204";
  };
  security.acme.certs."mail.${tools.meta.domain}".extraDomainNames = map
  (x: "${x}.${tools.meta.domain}") [
    "mx"
    "imap"
    "smtp"
  ];
}
