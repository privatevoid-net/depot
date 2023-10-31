{ config, ... }:

{
  services.external-storage = {
    underlays.garage = {
      subUser = "sub1";
      credentialsFile = ./secrets/storage-box-credentials.age;
      path = "/garage/${config.networking.hostName}";
      inherit (config.users.users.garage) uid;
      inherit (config.users.groups.garage) gid;
    };
  };

  services.garage.settings.data_dir = config.services.external-storage.underlays.garage.mountpoint;
}
