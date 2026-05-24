{ config, ... }:

{
  services.circus = {
    nodes.server = [ "thousandman" ];
    nixos.server = [ ./server.nix ];
    meshLinks.server.circusServer.link.protocol = "http";
  };

  ways = let
    host = builtins.head config.services.circus.nodes.server;
  in config.lib.forService "circus" {
    ci = {
      target = config.hostLinks.${host}.circusServer.url;
      domainSuffix = "manic.systems";
    };
  };
}
