{ depot, lib, ... }:

{
  imports = [
    ./catalog
    ./simulacrum/checks.nix
  ];

  options.cluster = lib.mkOption {
    type = lib.types.raw;
  };

  config.cluster = import ./. {
    inherit depot lib;
  };
}
