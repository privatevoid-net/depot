{ config, ... }:

{
  imports = [
    ./options.nix
  ];

  services.incandescence = {
    nodes = {
      provider = config.services.consul.nodes.agent;
    };
    nixos = {
      provider = [
        ./provider.nix
        ./provider-options.nix
      ];
    };
  };
}
