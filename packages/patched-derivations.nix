let
  tools = import ./lib/tools.nix;
  pins = import ./sources;
in with tools;
super: rec {
  hydra = (patch super.hydra-unstable "patches/base/hydra").override { nix = super.nixVersions.nix_2_8; };

  sssd = (super.sssd.override { withSudo = true; }).overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      ${super.removeReferencesTo}/bin/remove-references-to -t ${super.stdenv.cc.cc} $out/modules/ldb/memberof.so
    '';
    disallowedReferences = [ super.stdenv.cc.cc ];
  });

  jre17_standard = let
    jre = super.jre_minimal.override {
      jdk = super.jdk17_headless;
      modules = [
          "java.se"
          "jdk.naming.dns"
          "jdk.crypto.ec"
          "jdk.zipfs"
          "jdk.security.auth"
          "jdk.unsupported"
          "jdk.xml.dom"
          "jdk.sctp"
          "jdk.management"
      ];
    };
  in jre // { meta = jre.meta // { inherit (super.jdk17_headless.meta) platforms; }; };

  keycloak = super.keycloak.override {
    jre = jre17_standard;
  };

  oauth2-proxy = patch super.oauth2-proxy "patches/base/oauth2-proxy";

  tempo = super.tempo.overrideAttrs (_: {
    version = builtins.substring 1 (-1) pins.tempo.version;
    src = super.npins.mkSource pins.tempo;
    subPackages = [ "cmd/tempo" ];
  });
}
