{ config, lib, depot, ... }:
with depot.lib.nginx;
{
  links.bitwarden.protocol = "http";

  services.nginx.virtualHosts = mappers.mapSubdomains {
    keychain = vhosts.proxy config.links.bitwarden.url;
  };
  services.vaultwarden = {
    enable = true;
    backupDir = "/srv/storage/private/bitwarden/backups";
    config = {
      dataFolder = "/srv/storage/private/bitwarden/data";
      rocketPort = config.links.bitwarden.port;
    };
    #environmentFile = ""; # TODO: agenix
  };
  systemd.services.vaultwarden.serviceConfig = {
    ReadWriteDirectories = "/srv/storage/private/bitwarden";
  };
  systemd.services.backup-vaultwarden = {
    environment.DATA_FOLDER = lib.mkForce config.services.vaultwarden.config.dataFolder;
    serviceConfig = {
      ReadWriteDirectories = "/srv/storage/private/bitwarden";
    };
  };
}
