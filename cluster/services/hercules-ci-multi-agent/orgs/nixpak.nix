{ config, lib, inputs, pkgs, ... }:

{
  services.hercules-ci-agents.nixpak = {
    package = lib.mkForce inputs.self.packages.${pkgs.system}.hercules-ci-agent;
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-nixpak.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-nixpak.path;
    };
  };
}
