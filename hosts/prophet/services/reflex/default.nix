{ config, inputs, pkgs, tools, ... }:

let
  port = config.portsStr.nixIpfs;
in {
  reservePortsFor = [ "nixIpfs" ];

  systemd.services.nix-ipfs-cache = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${inputs.self.packages.${pkgs.system}.reflex-cache}/bin/reflex";
      DynamicUser = true;
      SupplementaryGroups = [ "ipfs" ];
      CacheDirectory = "nix-ipfs-cache";
    };
    environment = {
      REFLEX_PORT = port;
      IPFS_API = config.services.ipfs.apiAddress;
    };
  };

  services.nginx.virtualHosts."reflex.${tools.meta.domain}" = tools.nginx.vhosts.proxy "http://127.0.0.1:${port}";
}
