{
  services.websites = {
    nodes = {
      host = [ "checkmate" "VEGAS" "prophet" ];
    };
    nixos = {
      host = ./host.nix;
    };
  };
}
