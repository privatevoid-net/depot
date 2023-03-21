{
  services.acme-client = {
    nodes.client = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
    nixos.client = ./client.nix;
  };
}
