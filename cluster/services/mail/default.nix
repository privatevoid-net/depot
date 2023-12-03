{ depot, ... }:

{
  dns.records = let
    inherit (depot.lib.meta) domain adminEmail;
    mailServerAddr = depot.hours.VEGAS.interfaces.primary.addrPublic;
    mxAlias = {
      type = "CNAME";
      target = [ "mx.${domain}." ];
    };
  in {
    mx = {
      type = "A";
      target = [ mailServerAddr ];
    };
    smtp = mxAlias;
    imap = mxAlias;
    mail = mxAlias;
    MX = {
      name = "@";
      type = "MX";
      target = [ "0 mx.${domain}." ];
    };
    # compat for old email aliases
    "max.admin" = {
      type = "MX";
      target = [ "0 mx.${domain}." ];
    };
    SPF = {
      name = "@";
      type = "TXT";
      target = [ "v=spf1 mx a ip4:${mailServerAddr} ~all" ];
    };
    _dmarc = {
      type = "TXT";
      target = [ "v=DMARC1; p=reject; rua=mailto:${adminEmail}; ruf=mailto:${adminEmail}; sp=quarantine; ri=604800" ];
    };
    "${domain}._domainkey" = {
      type = "TXT";
      target = [ "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC9Q5VrGWEcG/CWZSWJl0tRQR3uiOkPH7AcNH+H7Gpa5S/E7tLZNyWuKOmNCRi/FKeqXcD5zIfI1sYsWZKOE70Un/ShCdRUzwD1Em8bO6yz/BbY1cBxHBQdCrH2ylMgn3UW0X1rM75EgJntAYkOqovtL78BtDbUhagO/0MTFpySpQIDAQAB" ];
    };
  };
}
