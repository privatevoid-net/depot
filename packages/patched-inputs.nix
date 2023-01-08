{
  perSystem = { filters, inputs', lib, pkgs, ... }:

  let
    tools = import ./lib/tools.nix;
    packages = builtins.mapAttrs (_: v: v.packages) inputs';
  in with tools;

  {
    packages = filters.doFilter filters.packages rec {
      inherit (packages.deploy-rs) deploy-rs;

      nix-super = packages.nix-super.nix;

      agenix = packages.agenix.agenix.override { nix = nix-super; };

      # hci-agent's build code does some funny shenanigans
      hercules-ci-agent = let
        original = packages.hercules-ci-agent.hercules-ci-agent;
        patchedNix = patch-rename-direct original.nix ({ version, ...}: "nix-${version}_hci1") "patches/extra/hercules-ci-agent/nix";
      in (original.override {
        # for hercules-ci-cnix-expr, hercules-ci-cnix-store
        nix = patchedNix;
        # for cachix
        pkgs = pkgs // { nix = patchedNix; };
      }).overrideAttrs (old: {
        # for hercules-ci-agent
        buildInputs = (lib.remove original.nix old.buildInputs) ++ [ patchedNix ];
      });

      hci = packages.hercules-ci-agent.hercules-ci-cli;
    };
  };
}