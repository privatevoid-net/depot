{ config, depot, ... }:

{
  services.gotosocial = {
    nodes.server = [ "thousandman" ];
    nixos.server = ./server.nix;
    meshLinks.server.gotosocial.link.protocol = "http";
    secrets = with config.services.gotosocial.nodes; {
      secrets = {
        nodes = server;
        owner = "root";
      };
    };
  };

  ways = let
    host = builtins.head config.services.gotosocial.nodes.server;
  in config.lib.forService "gotosocial" {
    trvke = {
      target = config.hostLinks.${host}.gotosocial.url;
      domainSuffix = "social";
    };
  };
}
