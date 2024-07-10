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
    secrets = let
      inherit (config.services.attic) nodes;
    in {
      serverToken = {
        nodes = nodes.server;
      };
      dbCredentials = {
        nodes = nodes.server;
        owner = "atticd";
      };
    };
  };

  garage = {
    keys.attic.locksmith = {
      nodes = config.services.attic.nodes.server;
      owner = "atticd";
      format = "aws";
    };
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
