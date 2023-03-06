{
  services.certificates = {
    nodes = {
      internal-wildcard = [ "checkmate" "VEGAS" ];
    };
    nixos = {
      internal-wildcard = [
        ./internal-wildcard.nix
      ];
    };
  };
}
