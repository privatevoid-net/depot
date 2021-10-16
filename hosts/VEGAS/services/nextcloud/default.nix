{ config, lib, pkgs, tools, ... }:
{
  age.secrets = {
    nextcloud-adminpass = {
      file = ../../../../secrets/nextcloud-adminpass.age;
      owner = "nextcloud";
      group = "nextcloud";
      mode = "0400";
    };
    nextcloud-dbpass = {
      file = ../../../../secrets/nextcloud-dbpass.age;
      owner = "nextcloud";
      group = "nextcloud";
      mode = "0400";
    };
  };
  services.nextcloud = {
    package = pkgs.nextcloud22;
    enable = true;
    https = true;
    hostName = "storage.${tools.meta.domain}";
    home = "/srv/storage/www-app/nextcloud";
    maxUploadSize = "4G";
    enableImagemagick = true;
    caching = with lib; flip genAttrs (_: true) [
      "apcu" "redis"
    ];

    autoUpdateApps = {
      enable = true;
      startAt = "02:00";
    };

    config = {
      dbhost = "/run/postgresql";
      dbtype = "pgsql";
      dbname = "storage";
      dbuser = "storage";
      dbpassFile = config.age.secrets.nextcloud-adminpass.path;

      overwriteProtocol = "https";

      adminuser = "sa";
      adminpassFile = config.age.secrets.nextcloud-dbpass.path;
    };
  };
  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    addSSL = true;
    enableACME = true;
  };
  systemd.services.phpfpm-nextcloud.aliases = [ "nextcloud.service" ];
}
