{ lib, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    checkConfig = true;
    package = pkgs.postgresql_12;
    dataDir = "/srv/storage/database/postgres-12/data";
  };
}
