{ config, cluster, ... }:

let
  inherit (config.networking) hostName;
in

{
  services.external-storage = {
    fileSystems.external = {
      mountpoint = "/srv/storage";
      authFile = ./secrets/external-storage-auth-${hostName}.age;
      backend = "s3c://${cluster.config.hostLinks.${hostName}.garageS3.tuple}/storage-${hostName}";
      backendOptions = [ "no-ssl" ];
    };
  };
}
