{ lib, ... }:
let
 filters = import ./system-filter.nix;
  doFilter' = system: filterSet: lib.filterAttrs (name: _:
    filterSet ? "${name}" -> builtins.elem system filterSet."${name}"
  );
in {
  imports = [
    ./projects.nix
    ./patched-inputs.nix
    ./catalog
  ];
  perSystem = { pkgs, self', system, ... }: let
    patched-derivations = import ./patched-derivations.nix (pkgs // { flakePackages = self'.packages; });
  in {
    _module.args.filters = filters // { doFilter = doFilter' system; };
    packages = doFilter' system filters.packages patched-derivations;
  };
}
