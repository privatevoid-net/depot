{ config, ... }:

{
  imports = [
    ./options.nix
    ./simulacrum/test-data.nix
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
    simulacrum = {
      enable = true;
      deps = [ "consul" "locksmith" ];
      settings = ./simulacrum/test.nix;
    };
  };
}
