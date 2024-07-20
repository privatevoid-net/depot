{
  services.frangiclave = {
    nodes = {
      server = [ "VEGAS" "grail" "prophet" ]; # 3 reliable nodes
      agent = []; # all nodes, for vault-agent, secret templates, etc.
    };
    nixos = {
      server = [
        ./server.nix
      ];
      agent = [];
    };
  };
}
