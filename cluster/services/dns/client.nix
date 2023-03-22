{ cluster, lib, ... }:

let
  recursors = lib.pipe (cluster.config.services.dns.nodes.coredns) [
    (map (node: cluster.config.hostLinks.${node}.dnsResolverBackend.ipv4))
  ];
in

{
  networking.nameservers = [ cluster.config.links.dnsResolver.ipv4 ] ++ recursors;
}
