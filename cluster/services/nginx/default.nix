{
  services.nginx = {
    nodes.host = [ "checkmate" "grail" "thunderskin" "VEGAS" "prophet" ];
    nixos.host = [
      ./nginx.nix
      ./countersiege.nix
      ./drop-bots.nix
    ];
  };
}
