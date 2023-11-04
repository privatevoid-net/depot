{
  services.certificates = {
    nodes = {
      internal-wildcard = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" ];
    };
    nixos = {
      internal-wildcard = [
        ./internal-wildcard.nix
      ];
    };
  };
}
