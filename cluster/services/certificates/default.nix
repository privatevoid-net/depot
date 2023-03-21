{
  services.certificates = {
    nodes = {
      internal-wildcard = [ "checkmate" "thunderskin" "VEGAS" ];
    };
    nixos = {
      internal-wildcard = [
        ./internal-wildcard.nix
      ];
    };
  };
}
