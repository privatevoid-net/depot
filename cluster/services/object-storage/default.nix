{ config, depot, ... }:

{
  services.object-storage = {
    nodes.host = [ "VEGAS" ];
    nixos.host = ./host.nix;
  };

  monitoring.blackbox.targets.object-storage = {
    address = "https://object-storage.${depot.lib.meta.domain}/minio/health/live";
    module = "https2xx";
  };

  dns.records = let
    serverAddrs = map
      (node: depot.hours.${node}.interfaces.primary.addrPublic)
      config.services.object-storage.nodes.host;
  in {
    object-storage.target = serverAddrs;
    "console.object-storage".target = serverAddrs;
    cdn.target = serverAddrs;
  };
}
