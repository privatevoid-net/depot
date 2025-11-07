{ config, cluster, lib, ... }:

let
  inherit (config) links;
in

{
  services.alloy.metrics.targets.ipfs = {
    address = links.ipfsMetrics.tuple;
    metricsPath = links.ipfsMetrics.path;
    labels.instance = config.networking.hostName;
  };
}
