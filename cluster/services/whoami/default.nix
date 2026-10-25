{ config, depot, ... }:

{
  services.whoami = {
    nodes.server = config.services.ways.nodes.host;
    nixos.server = ./server.nix;
  };

  dns.zones = config.lib.forService "whoami" {
    "${depot.lib.meta.domain}".records = {
      whoami.target = map
        (node: depot.hours.${node}.interfaces.primary.addrPublic)
        config.services.whoami.nodes.server;
    };
  };
}
