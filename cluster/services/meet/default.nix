{ config, depot, ... }:

{
  services.meet = {
    nodes.host = [ "prophet" ];
    nixos.host = ./host.nix;
  };

  dns.records.meet.target = map
    (node: depot.hours.${node}.interfaces.primary.addrPublic)
    config.services.meet.nodes.host;
}
