{ tools, ... }:

let
  inherit (tools.meta) domain;
in

{
  security.acme.certs."internal.${domain}" = {
    domain = "*.internal.${domain}";
    extraDomainNames = [ "*.internal.${domain}" ];
    dnsProvider = "pdns";
    group = "nginx";
  };
}
