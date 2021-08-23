let tools = import ./lib/tools.nix;
in with tools;
super: rec {
  kerberized-bind = super.bind.overrideAttrs (attrs: {
    configureFlags = attrs.configureFlags ++ [ "--with-gssapi=${super.krb5.dev}" ];
    buildInputs = attrs.buildInputs ++ [ super.krb5 ];
  });
  kerberized-dnsutils = kerberized-bind.dnsutils;
  kerberized-dig = kerberized-bind.dnsutils;

  hydra = (patch super.hydra-unstable "patches/base/hydra").override { nix = super.flakePackages.nix-super; };

  lain-ipfs = patch-rename super.ipfs "lain-ipfs" "patches/base/ipfs";
}
