{ config, depot, ... }:

{
  services.circus = {
    nodes.server = [ "thousandman" ];
    nixos.server = [ ./server.nix ];
    meshLinks.server.circusServer.link.protocol = "http";
    secrets = with config.services.circus.nodes; {
      s3Credentials = {
        nodes = server;
        owner = "root";
      };
      cacheKey = {
        nodes = server;
        owner = "circus";
      };
    };
  };

  ways = let
    host = builtins.head config.services.circus.nodes.server;
  in config.lib.forService "circus" {
    ci = {
      target = config.hostLinks.${host}.circusServer.url;
      domainSuffix = "manic.systems";
    };
  };

  dns.zones = config.lib.forService "circus" {
    "manic.systems".records = {
      circus-agent-rpc.target = map
        (node: depot.hours.${node}.interfaces.primary.addrPublic)
        config.services.circus.nodes.server;
    };
  };
}
