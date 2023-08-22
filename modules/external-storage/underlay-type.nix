{ config, lib, name, ... }:

with lib;

{
  options = {
    mountpoint = mkOption {
      type = types.path;
      default = "/mnt/remote-storage-backends/${name}";
    };
    storageBoxAccount = mkOption {
      type = types.str;
      # Private Void's main Storage Box
      default = "u357754";
    };
    host = mkOption {
      type = types.str;
      default = "${config.storageBoxAccount}.your-storagebox.de";
    };
    subUser = mkOption {
      type = types.str;
      example = "sub1";
    };
    credentialsFile = mkOption {
      type = types.path;
    };
    path = mkOption {
      type = types.path;
      default = "/";
    };
  };
}
