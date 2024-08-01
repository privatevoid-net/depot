{ lib, ... }:
with lib;

{
  options.hardware = {
    cpu = {
      cores = mkOption {
        type = types.ints.unsigned;
      };
    };
    memory = {
      gb = mkOption {
        type = types.ints.unsigned;
      };
    };
  };
}

