{ lib, name, ... }:

with lib;

{
  options = {
    mountpoint = mkOption {
      type = types.path;
    };
    unitName = mkOption {
      type = types.str;
      default = "remote-storage-${name}";
    };
    unitDescription = mkOption {
      type = types.str;
      default = "Remote Storage | ${name}";
    };
    encryptionKeyFile = mkOption {
      type = types.path;
    };
    cacheDir = mkOption {
      type = types.path;
      default = "/var/cache/remote-storage/${name}";
    };
    underlay = mkOption {
      type = types.str;
      default = "default";
    };
    dependentServices = mkOption {
      type = with types; listOf str;
      default = [];
    };
  };
}
