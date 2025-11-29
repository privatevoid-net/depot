{
  services.tor-client = {
    nodes.client = [ "VEGAS" "grail" ];
    nixos.client = ./client.nix;
  };
}
