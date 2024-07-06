{ depot, lib, ... }:

{
  imports = [
    ./catalog
  ];

  options.cluster = lib.mkOption {
    type = lib.types.raw;
  };

  config.cluster = import ./. {
    inherit depot lib;
  };
}
