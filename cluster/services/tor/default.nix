{
  services.tor = {
    nodes.client = [ "VEGAS" "grail" ];
    nixos.client = ./client.nix;
  };
}
