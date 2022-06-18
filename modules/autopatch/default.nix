{ pkgs, lib, config, inputs, ... }:
{
  nixpkgs.overlays = [
    (self: super: { flakePackages = inputs.self.packages.${pkgs.system}; })
    (self: super:
      (let
        patched = import ../../packages/patched-derivations.nix super;
      in {

        hydra-unstable = patched.hydra;

        inherit (patched) sssd tempo;

        jre = patched.jre17_standard;

        jre_headless = patched.jre17_standard;

      })
    )
  ];
}
