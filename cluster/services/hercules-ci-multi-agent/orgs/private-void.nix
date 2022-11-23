{ config, inputs, pkgs, ... }:

{
  services.hercules-ci-agents.private-void = {
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-private-void.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-private-void.path;
    };
  };
}
