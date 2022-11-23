{ config, inputs, pkgs, ... }:

{
  services.hercules-ci-agents.nixpak = {
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-nixpak.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-nixpak.path;
    };
  };
}
