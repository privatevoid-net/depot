{ config, lib, depot, pkgs, ... }:

{
  services.hercules-ci-agents.nixpak = {
    enable = true;
    package = depot.inputs.hercules-ci-agent.packages.hercules-ci-agent;
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-nixpak.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-nixpak.path;
    };
  };
}
