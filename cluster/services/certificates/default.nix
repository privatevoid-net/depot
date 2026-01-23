{
  services.certificates = {
    nodes = {
      internal-wildcard = [ "checkmate" "grail" "thousandman" "VEGAS" "prophet" ];
    };
    nixos = {
      internal-wildcard = [
        ./internal-wildcard.nix
      ];
    };
  };
}
