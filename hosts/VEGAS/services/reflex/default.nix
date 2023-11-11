{ config, depot, ... }:

{
  links.nixIpfs.protocol = "http";

  systemd.services.nix-ipfs-cache = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${depot.packages.reflex-cache}/bin/reflex";
      DynamicUser = true;
      SupplementaryGroups = [ "ipfs" ];
      CacheDirectory = "nix-ipfs-cache";
    };
    environment = {
      REFLEX_PORT = config.links.nixIpfs.portStr;
      IPFS_API = config.services.ipfs.apiAddress;
      IPFS_CLUSTER_API = config.services.ipfs-cluster.settings.api.restapi.http_listen_multiaddress;
      NIX_CACHES = toString [
        "https://cache.nixos.org"
        "https://cache.${depot.lib.meta.domain}"
      ];
    };
  };

  services.nginx.virtualHosts."reflex.${depot.lib.meta.domain}" = depot.lib.nginx.vhosts.proxy config.links.nixIpfs.url;
}
