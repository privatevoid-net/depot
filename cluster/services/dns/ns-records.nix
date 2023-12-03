{ config, depot, lib, ... }:

let
  cfg = config.services.dns;

  nsNodes = lib.imap1 (idx: node: {
    name = "eu${toString idx}.ns";
    value = {
      type = "A";
      target = [ depot.hours.${node}.interfaces.primary.addrPublic ];
    };
  }) cfg.nodes.authoritative;
in

{
  dns.records = lib.mkMerge [
    (lib.listToAttrs nsNodes)
    {
      NS = {
        name = "@";
        type = "NS";
        target = map (ns: "${ns.name}.${depot.lib.meta.domain}.") nsNodes;
      };
    }
  ];
}
