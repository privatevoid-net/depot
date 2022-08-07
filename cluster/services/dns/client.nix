{ cluster, ... }:

{
  networking.nameservers = [ cluster.config.links.dnsResolver.ipv4 ];
}
