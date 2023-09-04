{
  services.meet = {
    nodes.host = [ "prophet" ];
    nixos.host = ./host.nix;
  };
}
