{ config, cluster, ... }:

let
  inherit (config.networking) hostName;
  inherit (cluster.config.services.storage) secrets;
in

{
  storage.planetarium.fileSystems."storage-${hostName}" = {
    keyFile = secrets.externalStoragePlanetariumKey.path;
    mountPoint = "/srv/storage";
    mode = "0755";
  };
}
