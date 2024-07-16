{ config, depot, lib, ... }:

{
  options.reflection = lib.mkOption {
    description = "Peer into the Watchman's Glass.";
    type = lib.types.raw;
    readOnly = true;
    default = depot.hours.${config.networking.hostName};
  };
}
