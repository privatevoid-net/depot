{
  services.nginx = {
    nodes.host = [ "VEGAS" "prophet" ];
    nixos.host = [ ./nginx.nix ];
  };
}
