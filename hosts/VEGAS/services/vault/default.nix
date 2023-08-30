{ config, pkgs, depot, ... }:

{
  services.vault = {
    enable = true;
    storageBackend = "file";
    storagePath = "/srv/storage/private/vault";
    extraConfig = "ui = true";
    package = pkgs.vault-bin;
  };
  services.nginx.virtualHosts."vault.${depot.lib.meta.domain}" = depot.lib.nginx.vhosts.proxy "http://${config.services.vault.address}";
}
