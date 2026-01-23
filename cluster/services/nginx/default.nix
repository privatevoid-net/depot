{
  services.nginx = {
    nodes.host = [ "checkmate" "grail" "thousandman" "VEGAS" "prophet" ];
    nixos.host = [
      ./nginx.nix
      ./countersiege.nix
      ./drop-bots.nix
    ];
  };
}
