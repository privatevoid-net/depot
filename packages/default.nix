{ pkgs, inputs }@args:
let
  patched-derivations = import ./patched-derivations.nix (pkgs // { flakePackages = all; });
  patched-inputs = import ./patched-inputs.nix args;
  projects = import ./projects.nix args;
  all = patched-derivations
  // patched-inputs
  // projects.packages;
in {
  packages = pkgs.lib.filterAttrs (_: pkg: pkg ? meta.platforms -> builtins.elem pkgs.system pkg.meta.platforms) all;

  inherit (projects) devShells;
}
