{
  services.storage = {
    nodes = {
      external = [ "prophet" ];
      heresy = [ "VEGAS" ];
    };
    nixos = {
      external = [ ./external.nix ];
      heresy = [ ./heresy.nix ];
    };
  };
}
