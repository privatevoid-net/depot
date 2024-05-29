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
        ./bridges/discord.nix
      ];
      static = [
        ./federation.nix
        ./web-client.nix
      ];
    };
  };

  monitoring.blackbox.targets.matrix = {
    address = "https://matrix.${depot.lib.meta.domain}/_matrix/federation/v1/version";
    module = "https2xx";
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
