{ config, lib, ... }:

{
  garage = lib.mkIf config.simulacrum {
    keys.testkey = {};
    buckets.testbucket.allow.testKey = [ "read" "write" ];
  };
}
