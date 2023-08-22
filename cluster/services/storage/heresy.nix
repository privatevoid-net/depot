{
  services.external-storage = {
    underlays.heresy = {
      subUser = "sub1";
      credentialsFile = ./secrets/storage-box-credentials.age;
      path = "/fs/heresy";
    };
    fileSystems.heresy = {
      mountpoint = "/srv/heresy";
      unitName = "heresy";
      unitDescription = "Heresy Filesystem";
      encryptionKeyFile = ./secrets/heresy-encryption-key.age;
      underlay = "heresy";
    };
  };
}
