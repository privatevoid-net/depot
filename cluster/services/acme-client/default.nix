{
  services.acme-client = {
    nodes.client = [ "checkmate" "grail" "thousandman" "VEGAS" "prophet" ];
    nixos.client = ./client.nix;
    simulacrum.augments = ./augment.nix;
  };
}
