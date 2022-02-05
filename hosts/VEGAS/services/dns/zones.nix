{ lib, tools, ... }:

# upstream's zone generator is pretty bad, so...

# TODO: make this prettier

let
  inherit (tools.meta) domain;
  inherit (tools) nginx identity;

  externalSlave = { name, masters ? [ identity.dns.master.addr ], notify ? "no", alsoNotify ? [ "none" ] }: let
    zoneName = "${name}";
    file = "/var/named/slaves/ext_${zoneName}.db";
    mastersFormatted = builtins.concatStringsSep "; " masters;
    notifiersFormatted = builtins.concatStringsSep "; " alsoNotify;
  in ''
    zone "${zoneName}." IN {
      type slave;
      masters { ${mastersFormatted}; };
      file "${file}";
      allow-transfer { trusted; publicservers; };
      allow-query { any; };
      notify ${notify};
      also-notify { ${notifiersFormatted}; };
    };
  '';
  internalSlave' = domain: name: let
    zoneName  = "${name}${domain}";
    file = "/var/named/slaves/int_${zoneName}.db";
  in ''
    zone "${zoneName}." IN {
      type slave;
      masters { ${identity.dns.master.addr}; };
      file "${file}";
      allow-transfer { trusted; };
      allow-query { trusted; };
      notify no;
    };
  '';
  internalSlave = internalSlave' ".${domain}";
  revSlave = internalSlave' ".in-addr.arpa";
  toAttr = value: { inherit (value) name; inherit value; };
in
{
  services.bind.extraConfig = builtins.concatStringsSep "\n" ([
    (externalSlave { name = domain; notify = "explicit"; alsoNotify = [ "116.202.226.86" ]; })
    (externalSlave { name = "imagine-using-oca.ml"; notify = "explicit"; alsoNotify = [ "116.202.226.86" ]; })
    (externalSlave { name = "animus.com"; masters = [ "116.202.226.86" ]; })
  ] ++ map internalSlave [
    "virtual-machines"
    "core"
    "services"
    "ext"
    "int"
    "vpn"
    "find"
  ] ++ map revSlave [
    "0.10.10"
    "1.10.10"
    "2.10.10"
    "100.10"
  ] ++ map (internalSlave' "") [
    "void"
  ]);
}
