{ lib, depot }:

lib.evalModules {
  specialArgs = {
    inherit depot;
  };
  modules = [
    # Arbitrary variables to reference across multiple services
    ./lib/vars

    # Cluster-level port-magic
    ../modules/port-magic

    ./lib/services.nix
    ./lib/inject-nixos-config.nix
    ./lib/port-magic-multi.nix
    ./lib/mesh.nix

    ./import-services.nix
  ];
}
