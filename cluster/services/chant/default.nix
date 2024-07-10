{ config, ... }:

{
  services.chant = {
    nodes.listener = config.services.consul.nodes.agent;
    nixos.listener = [
      ./listener.nix
    ];
  };
}
