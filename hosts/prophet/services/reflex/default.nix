{ config, inputs, pkgs, tools, ... }:

{
  links.nixIpfs.protocol = "http";

  systemd.services.nix-ipfs-cache = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${inputs.self.packages.${pkgs.system}.reflex-cache}/bin/reflex";
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
        "https://cache.${tools.meta.domain}"
        "https://max.cachix.org"
      ];
    };
  };

  services.nginx.virtualHosts."reflex.${tools.meta.domain}" = tools.nginx.vhosts.proxy config.links.nixIpfs.url;
}
