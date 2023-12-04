{ config, depot, ... }:

{
  services.search = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  monitoring.blackbox.targets.search = {
    address = "https://search.${depot.lib.meta.domain}/healthz";
    module = "https2xx";
  };

  dns.records.search.target = map
    (node: depot.hours.${node}.interfaces.primary.addrPublic)
    config.services.search.nodes.host;
}
