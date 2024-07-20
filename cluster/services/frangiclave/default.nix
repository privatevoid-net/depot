{ config, ... }:

{
  services.frangiclave = {
    nodes = {
      server = [ "VEGAS" "grail" "prophet" ];
      cluster = config.services.frangiclave.nodes.server;
      agent = []; # all nodes, for vault-agent, secret templates, etc.
    };
    meshLinks = {
      server.link.protocol = "http";
      cluster.link.protocol = "http";
    };
    nixos = {
      server = [
        ./server.nix
      ];
      cluster = [];
      agent = [];
    };
  };
}
