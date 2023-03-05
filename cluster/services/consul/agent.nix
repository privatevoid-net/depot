{ config, cluster, lib, tools, ... }:

let
  inherit (tools.meta) domain;
  inherit (config.networking) hostName;
  inherit (cluster.config) hostLinks;
  cfg = cluster.config.services.consul;

  hl = hostLinks.${hostName}.consul;
in

{
  services.consul = {
    enable = true;
    webUi = true;
    extraConfig = {
      datacenter = "eu-central";
      domain = "sd-magic.${domain}.";
      server = true;
      node_name = config.networking.hostName;
      bind_addr = hl.ipv4;
      ports.serf_lan = hl.port;
      retry_join = map (hostName: hostLinks.${hostName}.consul.tuple) cfg.otherNodes.agent;
    };
  };
}
