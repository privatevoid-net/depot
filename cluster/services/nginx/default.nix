{
  services.nginx = {
    nodes.host = [ "VEGAS" "prophet" ];
    nixos.host = [ ./nginx.nix ./openssl-1.1.nix ];
  };
}
