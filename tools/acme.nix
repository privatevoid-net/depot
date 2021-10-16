# internal interface
{ toolsets }:
# external interface
{ config ? null, nameserver ? (toolsets.identity {}).dns.master.addr, ... }:
let
  tools = (self: {

    dns01 = {
      age.secrets.acme-dns-key = {
        file = ../secrets/acme-dns-key.age;
        owner = "acme";
        group = "acme";
        mode = "0400";
      };
      credentialsFile = builtins.toFile "acme-dns01-env" ''
        RFC2136_NAMESERVER=${nameserver}
        RFC2136_TSIG_KEY=acme-challenge.void
        RFC2136_TSIG_ALGORITHM=hmac-sha256
        RFC2136_TSIG_SECRET_FILE=${config.age.secrets.acme-dns-key.path}
      '';
    };

  }) tools;
in tools
