{
  services.acme-client = {
    nodes.client = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" ];
    nixos.client = ./client.nix;
  };
}
