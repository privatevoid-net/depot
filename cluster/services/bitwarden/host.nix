{ cluster, config, depot, ... }:
let
  patroni = cluster.config.links.patroni-pg-access;
in

with depot.lib.nginx;
{
  links.bitwarden.protocol = "http";

  system.ascensions.vaultwarden-data = {
    requiredBy = [ "vaultwarden.service" ];
    before = [ "vaultwarden.service" ];
  };

  services.locksmith.waitForSecrets.vaultwarden = [
    "patroni-vaultwarden"
  ];

  services.nginx.virtualHosts = mappers.mapSubdomains {
    keychain = vhosts.proxy config.links.bitwarden.url;
  };
  
  users = {
    users.vaultwarden.uid = 988;
    groups.vaultwarden.gid = 982;
  };

  services.vaultwarden = {
    enable = true;
    dbBackend = "postgresql";
    config = {
      dataFolder = "/srv/storage/private/bitwarden/data";
      rocketPort = config.links.bitwarden.port;
      databaseUrl = "postgresql://vaultwarden@${patroni.tuple}/vaultwarden?sslmode=disable";
    };
    environmentFile = [ "/run/locksmith/patroni-vaultwarden" ];
  };
  systemd.services.vaultwarden.serviceConfig = {
    ReadWriteDirectories = "/srv/storage/private/bitwarden";
  };
}
