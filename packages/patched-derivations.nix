let
  tools = import ./lib/tools.nix;
  pins = import ./sources;

  dvcMd5ToSha256 = old: {
    postPatch = (old.postPatch or "") + ''
      grep -Rwl md5 | xargs sed -i s/md5/sha256/g
    '';
  };

  dvcYamlToJson = old: {
    postPatch = (old.postPatch or "") + ''
      grep -Rwl yaml | xargs sed -i s/yaml/json/g
      grep -Rwl ruamel.json | xargs sed -i s/ruamel.json/ruamel.yaml/g
    '';
  };
in with tools;
super: rec {
  dvc = patch (super.dvc.overrideAttrs (old: let
    filteredBaseDeps = super.lib.subtractLists [
      super.python3Packages.dvc-data
      super.python3Packages.dvc-http
    ] old.propagatedBuildInputs;

    baseDeps = filteredBaseDeps ++ [
      dvc-data
      dvc-http
    ];
    patched = dvcMd5ToSha256 old;
    patched' = dvcYamlToJson patched;
  in patched' // {
    propagatedBuildInputs = with super.python3Packages; baseDeps ++ [
      aiobotocore
      boto3
      (s3fs.overrideAttrs (_: { postPatch = ''
          substituteInPlace requirements.txt \
            --replace "fsspec==2023.3.0" "fsspec" \
            --replace "aiobotocore~=2.1.0" "aiobotocore"
        '';
      }))
    ];
  })) "patches/base/dvc";

  dvc-data = (super.python3Packages.dvc-data.override {
    inherit dvc-objects;
  }).overrideAttrs dvcMd5ToSha256;

  dvc-http = super.python3Packages.dvc-http.override {
    inherit dvc-objects;
  };

  dvc-objects = super.python3Packages.dvc-objects.overrideAttrs dvcMd5ToSha256;

  forgejo = patch super.forgejo "patches/base/forgejo";

  garage = super.garage_0_8;

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

  tempo = (super.tempo.override { buildGoModule = super.buildGo119Module; }).overrideAttrs (_: {
    version = builtins.substring 1 (-1) pins.tempo.version;
    src = super.npins.mkSource pins.tempo;
    subPackages = [ "cmd/tempo" ];
  });
}
