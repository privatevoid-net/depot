{ config, cluster, depot, depot', ... }:

let
  inherit (depot.lib.meta) domain;
  inherit (config.networking) hostName;
  inherit (cluster.config) hostLinks;
  cfg = cluster.config.services.consul;

  hl = hostLinks.${hostName}.consul;
in

{
  links.consulAgent.protocol = "http";

  services.consul = {
    enable = true;
    webUi = true;
    package = depot'.packages.consul;
    extraConfig = {
      datacenter = "eu-central";
      domain = "sd-magic.${domain}.";
      recursors = [ "127.0.0.1" cluster.config.links.dnsResolver.ipv4 ];
      server = true;
      node_name = config.networking.hostName;
      bind_addr = hl.ipv4;
      ports.serf_lan = hl.port;
      retry_join = map (hostName: hostLinks.${hostName}.consul.tuple) (cfg.otherNodes.agent hostName);
      bootstrap_expect = assert builtins.length cfg.nodes.agent >= 3; 3;
      addresses.http = config.links.consulAgent.ipv4;
      ports.http = config.links.consulAgent.port;
    };
  };

  services.alloy.metrics.integrations.consul_exporter = {
    exporter = "consul";
    labels.instance = hostName;
    settings.server = config.links.consulAgent.url;
  };
}
