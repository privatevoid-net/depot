{
  services.acme-client = {
    nodes.client = [ "VEGAS" "prophet" ];
    nixos.client = ./client.nix;
  };
}
