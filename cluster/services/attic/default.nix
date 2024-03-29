{ config, depot, ... }:

{
  services.attic = {
    nodes = {
      server = [ "VEGAS" ];
    };
    nixos = {
      server = [
        ./server.nix
        ./binary-cache.nix
        ./nar-serve.nix
      ];
    };
  };

  garage = {
    keys.attic = { };
    buckets.attic = {
      allow.attic = [ "read" "write" ];
    };
  };

  dns.records = let
    serverAddrs = map
      (node: depot.hours.${node}.interfaces.primary.addrPublic)
      config.services.attic.nodes.server;
  in {
    cache-api.target = serverAddrs;
    cache.target = serverAddrs;
  };
}
