{ config, lib, tools, ... }:
with tools.nginx;
{
  services.nginx.virtualHosts = mappers.mapSubdomains {
    keychain = vhosts.proxy "http://127.0.0.1:${builtins.toString config.services.bitwarden_rs.config.rocketPort}";
  };
  services.bitwarden_rs = {
    enable = true;
    backupDir = "/srv/storage/private/bitwarden/backups";
    config = {
      dataFolder = "/srv/storage/private/bitwarden/data";
      rocketPort = 32002;
    };
    #environmentFile = ""; # TODO: agenix
  };
  systemd.services.bitwarden_rs.serviceConfig = {
    ReadWriteDirectories = "/srv/storage/private/bitwarden";
  };
  systemd.services.backup-bitwarden_rs.environment.DATA_FOLDER = lib.mkForce config.services.bitwarden_rs.config.dataFolder;
}
