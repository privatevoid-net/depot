{ config, lib, ... }:

{
  incandescence.providers.garage = {
    objects = {
      key = lib.attrNames config.garage.keys;
      bucket = lib.attrNames config.garage.buckets;
    };
  };
}
