{
  nixpkgs.overlays = [
    (self: super:
      (let
        patched = import ../../packages/patched-derivations.nix super;
      in {

        inherit (patched)
          kanidm
          prometheus-jitsi-exporter
          tempo
        ;

        jre_headless = patched.jre17_standard;

      })
    )
  ];
}
