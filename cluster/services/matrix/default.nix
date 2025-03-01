{ config, depot, ... }:

{
  services.matrix = {
    nodes = {
      homeserver = [ "VEGAS" ];
      static = config.services.websites.nodes.host;
    };
    nixos = {
      homeserver = [
        ./homeserver.nix
        ./coturn.nix
      ];
      static = [
        ./federation.nix
        ./web-client.nix
      ];
    };
    secrets = let
      inherit (config.services.matrix) nodes;
      default = {
        nodes = nodes.homeserver;
        owner = "matrix-synapse";
      };
    in {
      ldapConfig = default;
      dbConfig = default;
      turnConfig = default;
      keysConfig = default;
      coturnStaticAuth = {
        nodes = nodes.homeserver;
        owner = "turnserver";
      };
      discordAppServiceToken.nodes = nodes.homeserver;
    };
  };

  monitoring.blackbox.targets.matrix = {
    address = "https://matrix.${depot.lib.meta.domain}/_matrix/federation/v1/version";
    module = "https2xx";
  };

  garage = config.lib.forService "matrix" {
    keys.synapse.locksmith = {
      nodes = config.services.matrix.nodes.homeserver;
      owner = "matrix-synapse";
    };
    buckets.matrix-media.allow.synapse = [ "read" "write" ];
  };

  dns.records = let
    homeserverAddrs = map
      (node: depot.hours.${node}.interfaces.primary.addrPublic)
      config.services.matrix.nodes.homeserver;
  in {
    matrix.target = homeserverAddrs;
    stun.target = homeserverAddrs;
    turn.target = homeserverAddrs;
    chat.consulService = "static-lb";
  };
}
