{ config, inputs, pkgs, ... }:

{
  age.secrets = {
    hci-token = {
      file = ../../secrets + "/hci-token-${config.networking.hostName}.age";
      owner = "hercules-ci-agent";
      group = "hercules-ci-agent";
    };
    hci-cache-credentials = {
      file = ../../secrets + "/hci-cache-credentials-${config.networking.hostName}.age";
      owner = "hercules-ci-agent";
      group = "hercules-ci-agent";
    };
    hci-cache-config = {
      file = ../../secrets/hci-cache-config.age;
      owner = "hercules-ci-agent";
      group = "hercules-ci-agent";
    };
  };
  services.hercules-ci-agent = {
    enable = true;
    package = inputs.hercules-ci-agent.packages.${pkgs.system}.hercules-ci-agent;
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token.path;
      binaryCachesPath = config.age.secrets.hci-cache-config.path;
    };
  };
  systemd.services.hercules-ci-agent.environment = {
    AWS_SHARED_CREDENTIALS_FILE = config.age.secrets.hci-cache-credentials.path;
  };
}
