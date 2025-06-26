{ config, lib, ... }:

let
  inherit (config.links) garageMetrics;
in

{
  services.alloy.metrics.targets.garage = {
    address = garageMetrics.tuple;
    labels.instance = config.networking.hostName;
  };
}
