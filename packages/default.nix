{ pkgs, inputs }@args:
let
  patched-derivations = import ./patched-derivations.nix (pkgs // { flakePackages = all; });
  patched-inputs = import ./patched-inputs.nix args;
  packages = import ./packages.nix args;
  all = patched-derivations
  // patched-inputs
  // packages;
in all
