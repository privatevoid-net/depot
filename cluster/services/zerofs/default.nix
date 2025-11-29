{ config, lib, ... }:

{
  imports = [
    ./options.nix
    ./file-systems/planetarium.nix
  ];

  services.zerofs = {
    nodes.client = [ "VEGAS" "grail" "prophet" "thousandman" ];
    nodes.server = [ "grail" "thousandman" ];
    nixos.client = ./client.nix;
    nixos.server = ./server.nix;

    secrets = with config.services.zerofs.nodes; lib.mapAttrs' (name: fs: {
      name = "storageCredentials-${name}";
      value = {
        nodes = server;
        owner = "root";
      };
    }) config.storage.zerofs.fileSystems;

    meshLinks.server = lib.mapAttrs' (name: fs: {
      name = "zerofs-${name}";
      value.link.protocol = "nfs";
    }) config.storage.zerofs.fileSystems;
  };
}
