{ config, depot, ... }:

{
  services.attic = {
    nodes = {
      monolith = [ "VEGAS" "prophet" ];
      server = [ "VEGAS" "grail" "prophet" ];
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
    };
    meshLinks.server = {
      name = "attic";
      link.protocol = "http";
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
    cache.target = serverAddrs;
  };

  ways.cache-api = {
    consulService = "atticd";
    extras.extraConfig = ''
      client_max_body_size 4G;
    '';
  };
}
