let
  tools = import ./lib/tools.nix;
  pins = import ./sources;

  acceptVulnerabilities = drv:
    assert drv.meta ? knownVulnerabilities && builtins.length drv.meta.knownVulnerabilities > 0;
    drv.overrideAttrs (old: {
      meta = old.meta // {
        knownVulnerabilities = [];
      };
    });
in with tools;
super: rec {
  acme-dns = patch super.acme-dns "patches/base/acme-dns";

  cachix = patch super.cachix "patches/base/cachix";

  forgejo = patch super.forgejo "patches/base/forgejo";

  garage = patch super.garage_0_8 "patches/base/garage";

  jellyfin = super.jellyfin.override {
    jellyfin-ffmpeg = super.ffmpeg.override {
      withMfx = true;
    };
  };

  jitsi-meet-insecure = let
    olm-insecure = acceptVulnerabilities super.olm;
  in super.jitsi-meet.override { olm = olm-insecure; };

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
          "jdk.dynalink"
      ];
    };
  in jre // { meta = jre.meta // { inherit (super.jdk17_headless.meta) platforms; }; };

  kanidm = patch super.kanidm "patches/base/kanidm";

  keycloak = super.keycloak.override {
    jre = jre17_standard;
  };

  postgresql = super.postgresql_14;

  prometheus-jitsi-exporter = patch super.prometheus-jitsi-exporter "patches/base/prometheus-jitsi-exporter";

  s3ql = (patch super.s3ql "patches/base/s3ql").overrideAttrs (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [
      super.python3Packages.systemd
    ];
  });
}
