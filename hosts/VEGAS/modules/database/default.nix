{ lib, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    checkConfig = true;
    package = pkgs.postgresql_12;
    dataDir = "/srv/storage/database/postgres-12/data";
  };

  services.mysql = {
    enable = false;
    settings.mysqld.bind-address = "127.0.0.1";
    package = pkgs.mariadb;
    dataDir = "/srv/storage/database/mariadb/data";
  };
}
