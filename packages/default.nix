{ pkgs, inputs }@args:
let
  patched-derivations = import ./patched-derivations.nix pkgs;
  patched-inputs = import ./patched-inputs.nix args;
  packages = import ./packages.nix args;
in patched-derivations
// patched-inputs
// packages
