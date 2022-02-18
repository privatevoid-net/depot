{ config, pkgs, tools, ... }:

let
  py3 = pkgs.python3.withPackages (ps: with ps; [
    requests
    requests-unixsocket
  ]);

  port = config.portsStr.nixIpfs;
in {
  reservePortsFor = [ "nixIpfs" ];

  systemd.services.nix-ipfs-cache = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${py3}/bin/python3 -u ${./reflex.py} ${port}";
      DynamicUser = true;
      SupplementaryGroups = [ "ipfs" ];
      CacheDirectory = "nix-ipfs-cache";
    };
  };

  services.nginx.virtualHosts."reflex.${tools.meta.domain}" = tools.nginx.vhosts.proxy "http://127.0.0.1:${port}";
}
