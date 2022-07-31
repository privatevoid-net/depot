{ config, inputs, ... }:

with inputs;
{
  nix.nixPath = [
    "repl=/etc/nixos/flake-channels/system/repl.nix"
    "nixpkgs=/etc/nixos/flake-channels/nixpkgs"
  ];

  nix.registry = {
    system.flake = self;
    nixpkgs.flake = nixpkgs;
    default.flake = nixpkgs;
  };

  environment.etc = {
    "nixos/flake-channels/system".source = inputs.self;
    "nixos/flake-channels/nixpkgs".source = nixpkgs;
  };
}
