{
  services.cachix-deploy-agent = { config, ... }: {
    nodes.agent = [ "checkmate" "grail" "prophet" "VEGAS" "thunderskin" ];
    nixos.agent = ./agent.nix;
    secrets.token = {
      nodes = config.nodes.agent;
      shared = false;
    };
  };
}
