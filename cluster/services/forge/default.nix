{ config, depot, ... }:

{
  services.forge = {
    nodes.server = [ "VEGAS" ];
    nixos.server = ./server.nix;
  };

  dns.records.forge.target = map
    (node: depot.hours.${node}.interfaces.primary.addrPublic)
    config.services.forge.nodes.server;
}
