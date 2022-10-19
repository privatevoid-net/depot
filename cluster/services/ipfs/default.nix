{ tools, ... }:

{
  services.ipfs = {
    nodes = {
      node = [ "VEGAS" "prophet" ];
      gateway = [ "VEGAS" ];
    };
    nixos = {
      node = [
        ./node.nix
      ];
      gateway = [
        ./gateway.nix
        ./monitoring.nix
      ];
    };
  };
}
