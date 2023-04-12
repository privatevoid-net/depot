{
  services.certificates = {
    nodes = {
      internal-wildcard = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
    };
    nixos = {
      internal-wildcard = [
        ./internal-wildcard.nix
      ];
    };
  };
}
