{
  services.nginx = {
    nodes.host = [ "checkmate" "thunderskin" "VEGAS" "prophet" ];
    nixos.host = [ ./nginx.nix ];
  };
}
