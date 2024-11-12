let
  github = owner: repo: {
    type = "github";
    inherit owner repo;
  };
in {
  # own 
  hyprspace = github "hyprspace" "hyprspace";
  ai = github "nixified-ai" "flake";
  nix-super = github "privatevoid-net" "nix-super";
  nixpak = github "nixpak" "nixpak";

  # other
  nix = github "NixOS" "nix";
  flake-parts = github "hercules-ci" "flake-parts";
  home-manager = github "nix-community" "home-manager";
  dream2nix = github "nix-community" "dream2nix";
}
