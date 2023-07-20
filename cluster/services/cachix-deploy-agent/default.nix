{
  services.cachix-deploy-agent = {
    nodes.agent = [ "checkmate" "prophet" "VEGAS" "thunderskin" ];
    nixos.agent = ./agent.nix;
  };
}
