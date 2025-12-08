{
  services.acme-client = {
    nodes.client = [ "checkmate" "grail" "thunderskin" "thousandman" "VEGAS" "prophet" ];
    nixos.client = ./client.nix;
    simulacrum.augments = ./augment.nix;
  };
}
