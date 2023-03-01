{
  services.acme-client = {
    nodes.client = [ "checkmate" "VEGAS" "prophet" ];
    nixos.client = ./client.nix;
  };
}
