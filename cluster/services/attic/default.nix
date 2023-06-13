{
  services.attic = {
    nodes = {
      server = [ "VEGAS" ];
    };
    nixos = {
      server = ./server.nix;
    };
  };
}
