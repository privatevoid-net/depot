{ drv-backends, ... }:

{
  drv-backends.buildPythonPackage.imports = [
    drv-backends.mkDerivation
    ./interface.nix
    ./implementation.nix
  ];
}
