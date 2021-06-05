{ pkgs, lib, config, ... }:
{
  nixpkgs.overlays = [
    (self: super:
      (let
        patched = import ../../packages/patched-derivations.nix super;
      in {

        ipfs = patched.lain-ipfs;

        hydra-unstable = patched.hydra;

      } // lib.optionalAttrs config.krb5.enable {
        bind = patched.kerberized-bind;
        dnsutils = patched.kerberized-dnsutils;
        dig = patched.kerberized-dig;
      })
    )
  ];
}
