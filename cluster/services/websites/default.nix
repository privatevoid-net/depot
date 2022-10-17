{
  services.websites = {
    nodes = {
      host = [ "VEGAS" "prophet" ];
    };
    nixos = {
      host = ./host.nix;
    };
  };
}
