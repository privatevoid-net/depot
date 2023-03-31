{ config, lib, depot, pkgs, ... }:

{
  services.hercules-ci-agents.max = {
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-max.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-max.path;
    };
  };
}
