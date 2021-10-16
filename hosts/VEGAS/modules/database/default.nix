{ lib, pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    checkConfig = true;
    package = pkgs.postgresql_12;
    dataDir = "/srv/storage/database/postgres-12/data";
    authentication = lib.mkForce ''
      local all all trust
      host all all 127.0.0.1/32 trust
    '';
  };
}
