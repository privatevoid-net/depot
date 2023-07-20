{
  services.forge = {
    nodes.server = [ "VEGAS" ];
    nixos.server = ./server.nix;
  };
}
