{ config, depot, ... }:

{
  services.forge = {
    nodes.server = [ "VEGAS" ];
    nixos.server = ./server.nix;
    meshLinks.server = {
      name = "forge";
      link.protocol = "http";
    };
    secrets = with config.services.forge.nodes; {
      oidcSecret = {
        nodes = server;
        owner = "forgejo";
      };
      dbCredentials.nodes = server;
      s3AccessKeyID.nodes = server;
      s3SecretAccessKey.nodes = server;
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
