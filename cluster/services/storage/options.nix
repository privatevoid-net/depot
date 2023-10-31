{ lib, ... }:

{
  options.garage = {
    buckets = lib.mkOption {
      description = "Buckets to create in Garage.";
      type = with lib.types; attrsOf anything;
      default = {};
    };

    keys = lib.mkOption {
      description = "Keys to create in Garage.";
      type = with lib.types; attrsOf anything;
      default = {};
    };
  };
}
