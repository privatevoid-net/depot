{ pkgs, inputs }@args:
let
  patched-derivations = import ./patched-derivations.nix (pkgs // { flakePackages = all; });
  patched-inputs = import ./patched-inputs.nix args;
  projects = import ./projects.nix args;
  all = patched-derivations
  // patched-inputs
  // projects.packages;
in {
  packages = all;

  inherit (projects) devShells;
}
