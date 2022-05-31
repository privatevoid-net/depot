{ pkgs, inputs, system }@args:
let
  patched-derivations = import ./patched-derivations.nix (pkgs // { flakePackages = all; });
  patched-inputs = import ./patched-inputs.nix args;
  projects = import ./projects.nix args;
  all = patched-derivations
  // patched-inputs
  // projects.packages;
  filters = import ./system-filter.nix;
in {
  packages = pkgs.lib.filterAttrs (name: _:
    filters ? "${name}" -> builtins.elem system filters."${name}"
  ) all;

  inherit (projects) devShells checks;
}
