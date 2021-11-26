{ config, pkgs, tools, ... }:

{
  services.vault = {
    enable = true;
    storageBackend = "file";
    storagePath = "/srv/storage/private/vault";
    extraConfig = "ui = true";
    package = pkgs.vault-bin;
  };
  services.nginx.virtualHosts."vault.${tools.meta.domain}" = tools.nginx.vhosts.proxy "http://${config.services.vault.address}";
}
