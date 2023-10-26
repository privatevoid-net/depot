{ config, lib, depot, pkgs, ... }:

{
  services.hercules-ci-agents.max = {
    enable = true;
    package = depot.inputs.hercules-ci-agent.packages.hercules-ci-agent;
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-max.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-max.path;
    };
  };
}
