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
    trvke-social = {
      target = config.hostLinks.${host}.gotosocial.url;
      name = "@";
      domainSuffix = "trvke.social";
      extras.locations = {
        "/".proxyWebsockets = true;
        "= /app".return = "301 /app/";
      };
      staticLocations."/app/" = { depot', ... }: depot'.packages.phanpy-trvke-social;
    };
  };
}
