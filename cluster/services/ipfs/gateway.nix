{ cluster, config, depot, lib, ... }:
let
  inherit (depot.lib.meta) domain;
  gw = cluster.config.hostLinks.${config.networking.hostName}.ipfsGateway;
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

  services.ipfs.extraConfig.Gateway.PublicGateways = {
    "${domain}" = {
      Paths = [ "/ipfs" "/ipns" ];
      NoDNSLink = false;
      UseSubdomains = true;
    };
    "p2p.${domain}" = {
      Paths = [ "/routing" ];
      NoDNSLink = true;
      UseSubdomains = false;
    };
  };

  consul.services.ipfs-gateway = {
    mode = "external";
    unit = "ipfs";
    definition = {
      name = "ipfs-gateway";
      address = gw.ipv4;
      port = gw.port;
      checks = [
        {
          name = "IPFS Node";
          id = "service:ipfs-gateway:ipfs";
          interval = "60s";
          http = "${gw.url}/ipfs/QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn/"; # empty directory
          method = "HEAD";
        }
      ];
    };
  };
}
