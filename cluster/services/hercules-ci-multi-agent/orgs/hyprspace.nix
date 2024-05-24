{ config, lib, depot, pkgs, ... }:

{
  services.hercules-ci-agents.hyprspace = {
    enable = true;
    package = depot.inputs.hercules-ci-agent.packages.hercules-ci-agent;
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-hyprspace.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-hyprspace.path;
    };
  };
}
