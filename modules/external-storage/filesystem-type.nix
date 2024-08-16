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
    encrypt = mkOption {
      type = types.bool;
      default = false;
    };
    authFile = mkOption {
      type = types.path;
    };
    locksmithSecret = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    cacheDir = mkOption {
      type = types.path;
      default = "/var/cache/remote-storage/${name}";
    };
    underlay = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    backend = mkOption {
      type = with types; nullOr str;
    };
    backendOptions = mkOption {
      type = with types; listOf str;
      default = [];
    };
    dependentServices = mkOption {
      type = with types; listOf str;
      default = [];
    };
    commonArgs = mkOption {
      type = with types; listOf str;
      internal = true;
      readOnly = true;
    };
  };
}
