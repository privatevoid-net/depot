{ cluster, depot', ... }:

{
  services.cachix-agent = {
    enable = true;
    credentialsFile = cluster.config.services.cachix-deploy-agent.secrets.token.path;
    package = depot'.packages.cachix;
  };
}
