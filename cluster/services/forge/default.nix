{ config, depot, ... }:

{
  services.forge = {
    nodes.server = [ "VEGAS" ];
    nixos.server = ./server.nix;
    meshLinks.server.forge.link.protocol = "http";
    secrets = with config.services.forge.nodes; {
      oidcSecret = {
        nodes = server;
        owner = "forgejo";
      };
    };
  };

  ways = let
    host = builtins.head config.services.forge.nodes.server;
  in config.lib.forService "forge" {
    forge = {
      target = config.hostLinks.${host}.forge.url;
      extras.countersiege.locations = [
        "~ ^/.*/.*/commit/.*/"
        "~ ^/.*/.*/src/commit/.*/"
        "~ ^/.*/.*/raw/commit/.*/"
        "~ ^/.*/.*/commits/commit/.*/"
        "~ ^/.*/.*/blame/commit/.*/"
      ];
    };
  };

  patroni = config.lib.forService "forge" {
    databases.forge = {};
    users.forge.locksmith = {
      nodes = config.services.forge.nodes.server;
      format = "raw";
    };
  };

  garage = config.lib.forService "forge" {
    keys.forgejo.locksmith.nodes = config.services.forge.nodes.server;
    buckets.forgejo.allow.forgejo = [ "read" "write" ];
  };

  monitoring.blackbox.targets.forge = config.lib.forService "forge" {
    address = "https://forge.${depot.lib.meta.domain}/api/v1/version";
    module = "https2xx";
  };

  dns.records = config.lib.forService "forge" {
    "ssh.forge".target = map
      (node: depot.hours.${node}.interfaces.primary.addrPublic)
      config.services.forge.nodes.server;
  };
}
