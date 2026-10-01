{ config, depot, ... }:

{
  services.vineyard = {
    nodes.server = [ "thousandman" ];
    nixos.server = ./server.nix;
    meshLinks.server.vineyard.link.protocol = "http";
  };

  ways = let
    host = builtins.head config.services.vineyard.nodes.server;
  in config.lib.forService "vineyard" {
    relay = {
      domainSuffix = "manic.systems";
      target = config.hostLinks.${host}.vineyard.url;
      extras.locations."/".proxyWebsockets = true;
    };
  };

  monitoring.blackbox.targets.vineyard = config.lib.forService "vineyard" {
    address = "https://relay.manic.systems/healthz";
    module = "https2xx";
  };
}
