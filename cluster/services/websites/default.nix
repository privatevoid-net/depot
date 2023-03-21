{
  services.websites = {
    nodes = {
      host = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
    };
    nixos = {
      host = ./host.nix;
    };
  };
}
