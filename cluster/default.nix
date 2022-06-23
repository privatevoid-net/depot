{ lib, hostName }:

lib.evalModules {
  modules = [
    # Arbitrary variables to reference across multiple services
    ./lib/vars
    { vars = { inherit hostName; }; }

    # Cluster-level port-magic
    ../modules/port-magic

    ../tools/inject.nix
    ./lib/load-hosts.nix
    ./lib/services.nix
    ./lib/inject-nixos-config.nix

    ./import-services.nix
  ];
}