{
  services.tor-client = {
    nodes.client = [ "VEGAS" ];
    nixos.client = ./client.nix;
  };
}
