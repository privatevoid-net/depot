{ config, depot, ... }:

{
  services.forge = {
    nodes.server = [ "VEGAS" ];
    nixos.server = ./server.nix;
    meshLinks.server = {
      name = "forge";
      link.protocol = "http";
    };
  };

  ways.forge.target = let
    host = builtins.head config.services.forge.nodes.server;
  in config.hostLinks.${host}.forge.url;

  garage = {
    keys.forgejo = { };
    buckets.forgejo.allow.forgejo = [ "read" "write" ];
  };
}
