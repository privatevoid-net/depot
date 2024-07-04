{ cluster, config, depot, ... }:
with depot.lib.nginx;
let
  inherit (depot.lib.meta) domain;
  cfg = config.services.ipfs;
  gw = cluster.config.hostLinks.${config.networking.hostName}.ipfsGateway;
in
{
  users.users.nginx.extraGroups = [ cfg.group ];

  services.nginx.virtualHosts = {
    "ipfs.admin.${domain}" = vhosts.basic // {
      locations."/api".proxyPass = "http://unix:/run/ipfs/ipfs-api.sock:";
      locations."/ipns/webui.ipfs.io".proxyPass = "${gw.url}/ipns/webui.ipfs.io";
      locations."= /".return = "302 /ipns/webui.ipfs.io";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."ipfs.admin.${domain}" = { };
}
