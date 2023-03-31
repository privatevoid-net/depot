{ config, lib, depot, pkgs, ... }:

{
  age.secrets.hci-effects-secrets-private-void = {
    file = ../secrets/hci-effects-secrets-private-void.age;
    owner = "hci-private-void";
    group = "hci-private-void";
  };
  services.hercules-ci-agents.private-void = {
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-private-void.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-private-void.path;
      secretsJsonPath = config.age.secrets.hci-effects-secrets-private-void.path;
    };
  };
}
