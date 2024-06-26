{ config, cluster, ... }:

let
  inherit (config.networking) hostName;
in

{
  services.external-storage = {
    fileSystems.external = {
      mountpoint = "/srv/storage";
      authFile = ./secrets/external-storage-auth-${hostName}.age;
      backend = "s3c4://${cluster.config.links.garageS3.hostname}/storage-${hostName}";
      backendOptions = [ "disable-expect100" ];
    };
  };
}
