{
  lib,
  buildNpmPackage,
  fetchFromGitea,
  makeWrapper,
  mkNpinsSource,
  pins,
}:

let
  inherit (pins) phanpy;

  app = buildNpmPackage {
    pname = "phanpy";
    inherit (phanpy) version;

    src = mkNpinsSource phanpy;

    npmDepsHash = "sha256-02comyhYcY7Q71Cx9RCWIeKz1RwNcJPtSR5/EB2v+jU=";

    env = {
      PHANPY_CLIENT_NAME = "TRVKE Social";
      PHANPY_WEBSITE = "https://trvke.social/app/";
      PHANPY_DEFAULT_INSTANCE = "trvke.social";
      PHANPY_DISALLOW_ROBOTS = 1;
    };

    installPhase = ''
      destDir=$out/share/www/trvke.social
      mkdir -p $destDir
      cp -r dist/. $destDir
    '';

    passthru.webroot = "${app}/share/www/trvke.social";
  };
in app
