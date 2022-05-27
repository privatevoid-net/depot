let tools = import ./lib/tools.nix;
in with tools;
super: rec {
  kerberized-bind = super.bind.overrideAttrs (attrs: {
    configureFlags = attrs.configureFlags ++ [ "--with-gssapi=${super.krb5.dev}" ];
    buildInputs = attrs.buildInputs ++ [ super.krb5 ];
  });
  kerberized-dnsutils = kerberized-bind.dnsutils;
  kerberized-dig = kerberized-bind.dnsutils;

  hydra = (patch super.hydra-unstable "patches/base/hydra").override { nix = super.nix_2_4; };

  lain-ipfs = patch-rename (super.ipfs_latest or super.ipfs) "lain-ipfs" "patches/base/ipfs";

  sssd = super.sssd.override { withSudo = true; };

  jre17_standard = super.jre_minimal.override {
    jdk = super.jdk17_headless;
    modules = [
        "java.se"
        "jdk.naming.dns"
        "jdk.crypto.ec"
        "jdk.zipfs"
    ];
  };
}
