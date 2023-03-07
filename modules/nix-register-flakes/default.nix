{ depot, ... }:

with depot.inputs;
{
  nix.nixPath = [
    "repl=/etc/nixos/flake-channels/system/repl.nix"
    "nixpkgs=/etc/nixos/flake-channels/nixpkgs"
  ];

  nix.registry = {
    system.flake = depot;
    nixpkgs.flake = nixpkgs;
    default.flake = nixpkgs;
  };

  environment.etc = {
    "nixos/flake-channels/system".source = depot;
    "nixos/flake-channels/nixpkgs".source = nixpkgs;
  };
}
