{ pkgs, lib, config, inputs, ... }:
{
  nixpkgs.overlays = [
    (self: super: { flakePackages = inputs.self.packages.${pkgs.system}; })
    (self: super:
      (let
        patched = import ../../packages/patched-derivations.nix super;
      in {

        ipfs = patched.lain-ipfs;

        hydra-unstable = patched.hydra;

        inherit (patched) sssd;

        jre = patched.jre17_standard;

        jre_headless = patched.jre17_standard;

      } // lib.optionalAttrs config.krb5.enable {
        bind = patched.kerberized-bind;
        dnsutils = patched.kerberized-dnsutils;
        dig = patched.kerberized-dig;
      })
    )
  ];
}
