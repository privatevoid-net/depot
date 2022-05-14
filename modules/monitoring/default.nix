{ config, hosts, ... }:
let
  myNode = hosts.${config.networking.hostName};
in
{
  services.prometheus.exporters = {
    node = {
      enable = true;
      listenAddress = myNode.hypr.addr;
    };

    jitsi = {
      enable = config.services.jitsi-meet.enable;
      listenAddress = myNode.hypr.addr;
      interval = "60s";
    };
  };
}
