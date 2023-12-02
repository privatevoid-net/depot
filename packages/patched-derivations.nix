let
  tools = import ./lib/tools.nix;
  pins = import ./sources;

in with tools;
super: rec {
  cachix = patch super.cachix "patches/base/cachix";

  forgejo = patch super.forgejo "patches/base/forgejo";

  garage = patch super.garage_0_8 "patches/base/garage";

  jellyfin = patch (super.jellyfin.override {
    ffmpeg = super.ffmpeg.override {
      withMfx = true;
    };
  }) "patches/base/jellyfin";

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

  powerdns-admin = let
    package = super.powerdns-admin.override {
      python3 = super.python3.override {
        packageOverrides = _: _: { python3-saml = null; };
      };
    };
  in patch package "patches/base/powerdns-admin";

  prometheus-jitsi-exporter = patch super.prometheus-jitsi-exporter "patches/base/prometheus-jitsi-exporter";

  s3ql = (patch super.s3ql "patches/base/s3ql").overrideAttrs (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [
      super.python3Packages.systemd
    ];
  });

  tempo = (super.tempo.override { buildGoModule = super.buildGo121Module; }).overrideAttrs (_: {
    version = builtins.substring 1 (-1) pins.tempo.version;
    src = super.npins.mkSource pins.tempo;
    subPackages = [ "cmd/tempo" ];
  });
}
