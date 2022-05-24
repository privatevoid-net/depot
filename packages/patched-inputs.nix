{ inputs, pkgs, system, ... }:
let
  tools = import ./lib/tools.nix;
  packages = builtins.mapAttrs (_: v: v.packages.${system}) inputs;
in with tools;
rec {
  inherit (packages.deploy-rs) deploy-rs;

  nix-super = packages.nix-super.nix;

  agenix = packages.agenix.agenix.override { nix = nix-super; };

  hercules-ci-agent = packages.hercules-ci-agent.hercules-ci-agent.override { nix = nix-super; };

  hci = packages.hercules-ci-agent.hercules-ci-cli.override { nix = nix-super; };
}
