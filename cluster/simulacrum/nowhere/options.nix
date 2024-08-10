{ lib, ... }:

{
  options.nowhere = {
    names = lib.mkOption {
      description = "Hostnames that point Nowhere.";
      type = with lib.types; attrsOf str;
      default = {};
    };
    certs = lib.mkOption {
      description = "Snakeoil certificate packages.";
      type = with lib.types; attrsOf package;
      default = {};
    };
  };
}
