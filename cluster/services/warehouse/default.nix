{ config, depot, ... }:

{
  services.warehouse = {
    nodes.host = [ "VEGAS" ];
    nixos.host = [ ./host.nix ];
  };

  dns.records.warehouse.target = map
    (node: depot.hours.${node}.interfaces.primary.addrPublic)
    config.services.warehouse.nodes.host;
}
