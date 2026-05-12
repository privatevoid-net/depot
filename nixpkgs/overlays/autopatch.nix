{ lib, ... }:

{
  flake.overlays.autopatch = final: prev: lib.pipe ../../patches/auto [
    builtins.readDir
    (lib.filterAttrs (_: type: type == "directory"))
    (lib.mapAttrs (name: _: prev.${name}.overrideAttrs (old: {
      patches = (old.patches or []) ++ (lib.filesystem.listFilesRecursive ../../patches/auto/${name});
    })))
  ];
}
