{ pkgs, lib, config, inputs, ... }:
{
  nixpkgs.overlays = [
    (self: super:
      (let
        patched = import ../../packages/patched-derivations.nix super;
      in {

        inherit (patched) sssd tempo;

        jre_headless = patched.jre17_standard;

      })
    )
  ];
}
