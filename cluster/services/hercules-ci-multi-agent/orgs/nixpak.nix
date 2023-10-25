{ config, lib, depot, pkgs, ... }:

{
  services.hercules-ci-agents.nixpak = {
    enable = true;
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-nixpak.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-nixpak.path;
    };
  };
}
