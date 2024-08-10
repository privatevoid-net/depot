{ config, ... }:

{
  services.locksmith = {
    nodes = {
      receiver = config.services.consul.nodes.agent;
      provider = config.services.consul.nodes.agent;
    };
    nixos = {
      receiver = [
        ./receiver.nix
      ];
      provider = [
        ./provider.nix
      ];
    };
    simulacrum.deps = [ "chant" "consul" ];
  };
}
