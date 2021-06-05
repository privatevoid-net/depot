let tools = import ./lib/tools.nix;
in with tools;
{ inputs, pkgs, ... }: rec {
  deploy-rs = patch inputs.deploy-rs.packages.x86_64-linux.deploy-rs "patches/custom/deploy-rs";

  nix-super-unstable = let
    system = "x86_64-linux";
    pkgs = import inputs.nixpkgs { inherit system;
      overlays = [
        inputs.nix-super-unstable.overlay
        (self: super: rec {
          nixSuperUnstable = patch-rename-direct super.nix (attrs: "nix-super-unstable-${attrs.version}") "patches/base/nix";
        })
      ];
    };
  in pkgs.nixSuperUnstable;

  agenix = inputs.agenix.packages.x86_64-linux.agenix.override { nix = nix-super-unstable; };
}
