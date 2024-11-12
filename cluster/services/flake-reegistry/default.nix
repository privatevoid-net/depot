{ lib, ... }:

{
  ways.registry.static = { depot, pkgs, ... }: pkgs.writeTextDir "flake-registry.json" (let
    flakes = {
      depot = {
        type = "tarball";
        url = "https://forge.${depot.lib.meta.domain}/${depot.lib.meta.domain}/depot/archive/master.tar.gz";
      };
      depot-nixpkgs = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        inherit (depot.inputs.nixpkgs.sourceInfo) rev narHash lastModified;
      };
      blank = {
        type = "github";
        owner = "divnix";
        repo = "blank";
        inherit (depot.inputs.blank.sourceInfo) rev narHash lastModified;
      };
    } // import ./extra-flakes.nix;
  in builtins.toJSON {
    version = 2;
    flakes = lib.pipe flakes [
      (lib.attrsToList)
      (map (f: {
        from = {
          type = "indirect";
          id = f.name;
        };
        to = f.value;
      }))
    ];
  });
}
