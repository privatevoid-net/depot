{ inputs, pkgs, system, ... }:
let
  tools = import ./lib/tools.nix;
  packages = builtins.mapAttrs (_: v: v.packages.${system}) inputs;
in with tools;
rec {
  inherit (packages.deploy-rs) deploy-rs;

  nix-super = packages.nix-super.nix;

  agenix = packages.agenix.agenix.override { nix = nix-super; };
}
