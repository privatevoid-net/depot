{ lib, depot, hostName }:

lib.evalModules {
  specialArgs = {
    inherit depot;
  };
  modules = [
    # Arbitrary variables to reference across multiple services
    ./lib/vars
    { vars = { inherit hostName; }; }

    # Cluster-level port-magic
    ../modules/port-magic

    ../tools/inject.nix
    ./lib/services.nix
    ./lib/inject-nixos-config.nix
    ./lib/port-magic-multi.nix

    ./import-services.nix
  ];
}