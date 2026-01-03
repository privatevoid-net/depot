{ config, ... }:

{
  services.planetarium = {
    nodes.mount = [ "VEGAS" "prophet" ];
    nixos.mount = ./mount.nix;

    secrets.storageCredentials = with config.services.planetarium.nodes; {
      nodes = mount;
      owner = "root";
    };

    simulacrum = {
      enable = true;
      deps = [ ];
      settings = ./simulacrum/test.nix;
    };
  };
}
