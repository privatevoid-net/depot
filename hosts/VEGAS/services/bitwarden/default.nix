{ config, lib, tools, ... }:
with tools.nginx;
{
  reservePortsFor = [ "bitwarden" ];

  services.nginx.virtualHosts = mappers.mapSubdomains {
    keychain = vhosts.proxy "http://127.0.0.1:${config.portsStr.bitwarden}";
  };
  services.vaultwarden = {
    enable = true;
    backupDir = "/srv/storage/private/bitwarden/backups";
    config = {
      dataFolder = "/srv/storage/private/bitwarden/data";
      rocketPort = config.ports.bitwarden;
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
