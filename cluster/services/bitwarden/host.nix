{ cluster, config, depot, ... }:
let
  patroni = cluster.config.links.patroni-pg-access;
in

with depot.lib.nginx;
{
  links.bitwarden.protocol = "http";

  services.locksmith.waitForSecrets.vaultwarden = [
    "patroni-vaultwarden"
  ];

  services.nginx.virtualHosts = mappers.mapSubdomains {
    keychain = vhosts.proxy config.links.bitwarden.url;
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
