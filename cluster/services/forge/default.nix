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
    };
  };

  ways.forge.target = let
    host = builtins.head config.services.forge.nodes.server;
  in config.hostLinks.${host}.forge.url;

  garage = {
    keys.forgejo.locksmith.nodes = config.services.forge.nodes.server;
    buckets.forgejo.allow.forgejo = [ "read" "write" ];
  };

  monitoring.blackbox.targets.forge = {
    address = "https://forge.${depot.lib.meta.domain}/api/v1/version";
    module = "https2xx";
  };

  dns.records."ssh.forge".target = map
    (node: depot.hours.${node}.interfaces.primary.addrPublic)
    config.services.forge.nodes.server;
}
