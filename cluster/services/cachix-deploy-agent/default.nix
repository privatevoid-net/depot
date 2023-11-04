{
  services.cachix-deploy-agent = {
    nodes.agent = [ "checkmate" "grail" "prophet" "VEGAS" "thunderskin" ];
    nixos.agent = ./agent.nix;
  };
}
