{
  services.storage = {
    nodes.heresy = [ "VEGAS" ];
    nixos.heresy = [
      ./heresy.nix
    ];
  };
}
