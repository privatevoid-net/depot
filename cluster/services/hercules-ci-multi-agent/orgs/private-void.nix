{ config, lib, inputs, pkgs, ... }:

{
  services.hercules-ci-agents.private-void = {
    package = lib.mkForce inputs.self.packages.${pkgs.system}.hercules-ci-agent;
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-private-void.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-private-void.path;
    };
  };
}
