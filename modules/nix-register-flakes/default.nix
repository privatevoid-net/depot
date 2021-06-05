{ config, inputs, ... }:

with inputs;
{
  nix.nixPath = [
    "repl=/etc/nixos/flake-channels/system/repl.nix"
    "nixpkgs=/etc/nixos/flake-channels/nixpkgs"
    "home-manager=/etc/nixos/flake-channels/home-manager"
  ];

  nix.registry = {
    system.flake = self;
    nixpkgs.flake = nixpkgs;
    default.flake = nixpkgs;
    home-manager.flake = home-manager;
  };

  environment.etc = {
    "nixos/flake-channels/system".source = inputs.self;
    "nixos/flake-channels/nixpkgs".source = nixpkgs;
    "nixos/flake-channels/home-manager".source = home-manager;
  };
}
