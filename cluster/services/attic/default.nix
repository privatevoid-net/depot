{ config, depot, ... }:

{
  services.attic = {
    nodes = {
      monolith = [ "VEGAS" "prophet" ];
      server = [ "VEGAS" "grail" "prophet" ];
      cache-client = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" ];
    };
    nixos = {
      monolith = [
        ./server.nix
      ];
      server = [
        ./server.nix
        ./binary-cache.nix
        ./nar-serve.nix
      ];
      cache-client = [
        ./builder-cache-client.nix
      ];
    };
    meshLinks.server.attic.link.protocol = "http";
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

  garage = config.lib.forService "attic" {
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
  in config.lib.forService "attic" {
    cache.target = serverAddrs;
  };

  ways = config.lib.forService "attic" {
    cache-api = {
      consulService = "atticd";
      extras.extraConfig = ''
        client_max_body_size 4G;
      '';
    };
  };
}
