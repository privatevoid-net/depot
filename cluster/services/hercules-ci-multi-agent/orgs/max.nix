{ config, lib, inputs, pkgs, ... }:

{
  services.hercules-ci-agents.max = {
    package = lib.mkForce inputs.self.packages.${pkgs.system}.hercules-ci-agent;
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-max.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-max.path;
    };
  };
}
