let
  tools = import ./lib/tools.nix;
in with tools;
super: rec {
  garage = patch super.garage_2 "patches/base/garage";

  jre= let
    jre = super.jre_minimal.override {
      jdk = super.jdk21_headless;
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
          "jdk.jfr"
      ];
    };
  in jre // { meta = jre.meta // { inherit (super.jdk21_headless.meta) platforms; }; };

  kanidm = patch super.kanidm_1_10 "patches/base/kanidm";

  keycloak = super.keycloak.override {
    jre_headless = jre;
  };

  postgresql = super.postgresql_14;

  s3ql = (patch super.s3ql "patches/base/s3ql").overrideAttrs (old: {
    propagatedBuildInputs = old.propagatedBuildInputs ++ [
      super.python3Packages.systemd-python
    ];
  });
}
