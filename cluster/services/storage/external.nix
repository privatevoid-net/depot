{ config, cluster, ... }:

let
  inherit (config.networking) hostName;
in

{
  services.external-storage = {
    fileSystems.external = {
      mountpoint = "/srv/storage";
      locksmithSecret = "garage-storage-${hostName}";
      backend = "s3c4://${cluster.config.links.garageS3.hostname}/storage-${hostName}";
      backendOptions = [ "disable-expect100" ];
    };
  };
}
