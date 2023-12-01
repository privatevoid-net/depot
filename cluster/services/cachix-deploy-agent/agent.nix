{ config, depot, ... }:

{
  age.secrets.cachixDeployToken.file = ./credentials/${config.networking.hostName}.age;

  services.cachix-agent = {
    enable = true;
    credentialsFile = config.age.secrets.cachixDeployToken.path;
    package = depot.packages.cachix;
  };
}
