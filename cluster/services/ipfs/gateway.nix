{ config, lib, tools, ... }:
with tools.nginx;
let
  inherit (tools.meta) domain;
  gw = config.links.ipfsGateway;
  cfg = config.services.ipfs;
  metrics = config.links.ipfsMetrics;
in
{
  users.users.nginx.extraGroups = [ cfg.group ];

  links.ipfsMetrics = {
    protocol = "http";
    path = "/debug/metrics/prometheus";
  };

  services.nginx.virtualHosts = {
    "top-level.${domain}".locations = {
      "~ ^/ip[fn]s" = {
        proxyPass = gw.url;
        extraConfig = ''
          add_header X-Content-Type-Options "";
          add_header Access-Control-Allow-Origin *;
        '';
      };
    };
    ipfs-metrics = {
      serverName = null;
      listen = lib.singleton {
        addr = metrics.ipv4;
        inherit (metrics) port;
      };
      extraConfig = "access_log off;";
      locations."/".return = "204";
      locations."${metrics.path}".proxyPass = "http://unix:/run/ipfs/ipfs-api.sock:";
    };
  };
  security.acme.certs."ipfs.${domain}" = {
    domain = "*.ipfs.${domain}";
    extraDomainNames = [ "*.ipns.${domain}" ];
    dnsProvider = "pdns";
    group = "nginx";
  };

  services.nginx.virtualHosts."ipfs.${domain}" = vhosts.basic // {
    serverName = "~^(.+)\.(ip[fn]s)\.${domain}$";
    enableACME = false;
    useACMEHost = "ipfs.${domain}";
    locations = {
      "/" = {
        proxyPass = gw.url;
        extraConfig = ''
          add_header X-Content-Type-Options "";
          add_header Access-Control-Allow-Origin *;
        '';
      };
    };
  };

  consul.services.ipfs-gateway = {
    mode = "external";
    unit = "ipfs";
    definition = {
      name = "ipfs-gateway";
      address = gw.ipv4;
      inherit (gw) port;
      checks = lib.singleton {
        interval = "60s";
        http = "${gw.url}/ipfs/QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn/"; # empty directory
        method = "HEAD";
      };
    };
  };
}
