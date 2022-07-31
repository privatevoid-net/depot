{ inputs, lib, ... }:
let
 filters = import ./system-filter.nix;
  doFilter' = system: filterSet: pkgSet: lib.filterAttrs (name: _:
    filterSet ? "${name}" -> builtins.elem system filterSet."${name}"
  ) pkgSet;
in {
  imports = [
    ./projects.nix
    ./patched-inputs.nix
  ];
  perSystem = { pkgs, self', system, ... }: let
    patched-derivations = import ./patched-derivations.nix (pkgs // { flakePackages = self'.packages; });
  in {
    _module.args.filters = filters // { doFilter = doFilter' system; };
    packages = doFilter' system filters.packages patched-derivations;
  };
}
