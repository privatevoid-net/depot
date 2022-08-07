{
  services.acme-client = {
    nodes.client = [ "VEGAS" ];
    nixos.client = ./client.nix;
  };
}
