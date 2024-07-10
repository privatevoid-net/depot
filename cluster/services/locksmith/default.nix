{ config, ... }:

{
  services.locksmith = {
    nodes.receiver = config.services.consul.nodes.agent;
    nixos.receiver = [
      ./receiver.nix
    ];
  };
}
