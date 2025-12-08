{
  services.certificates = {
    nodes = {
      internal-wildcard = [ "checkmate" "grail" "thunderskin" "thousandman" "VEGAS" "prophet" ];
    };
    nixos = {
      internal-wildcard = [
        ./internal-wildcard.nix
      ];
    };
  };
}
