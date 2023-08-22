{ config, ... }:

{
  services.external-storage = {
    underlays.default = {
      subUser = "sub1";
      credentialsFile = ./secrets/storage-box-credentials.age;
      path = "/fs/by-host/${config.networking.hostName}";
    };
    fileSystems.external = {
      mountpoint = "/srv/storage";
      encryptionKeyFile = ./secrets/external-storage-encryption-key-${config.networking.hostName}.age;
    };
  };
}
