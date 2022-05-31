{ pkgs, inputs, system }@args:
let
  patched-derivations = import ./patched-derivations.nix (pkgs // { flakePackages = all; });
  patched-inputs = import ./patched-inputs.nix args;
  projects = import ./projects.nix args;
  all = patched-derivations
  // patched-inputs
  // projects.packages;
  filters = import ./system-filter.nix;
  doFilter = filterSet: pkgSet: pkgs.lib.filterAttrs (name: _:
    filterSet ? "${name}" -> builtins.elem system filterSet."${name}"
  ) pkgSet;
in {
  packages = doFilter filters.packages all;

  checks = doFilter filters.checks projects.checks;

  inherit (projects) devShells;
}
