{
  services.warehouse = {
    nodes.host = [ "VEGAS" ];
    nixos.host = [ ./host.nix ];
  };
}
