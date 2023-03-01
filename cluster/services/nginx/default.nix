{
  services.nginx = {
    nodes.host = [ "checkmate" "VEGAS" "prophet" ];
    nixos.host = [ ./nginx.nix ];
  };
}
