{ stdenvNoCC, fetchzip, pins }:

let
  inherit (pins) cinny;
  repo = cinny.repository;
in

let
  app = stdenvNoCC.mkDerivation rec {
    name = "cinny-bin";
    version = builtins.substring 1 (-1) cinny.version;

    src = fetchzip {
      name = "cinny-tarball-${version}";
      url = "https://github.com/${repo.owner}/${repo.repo}/releases/download/${cinny.version}/cinny-${cinny.version}.tar.gz";
      sha256 = "sha256-u44fWBRfD/ZTXkuJHgcdiWo293aTqF0/Iz5rBPRuieg=";
    };

    buildCommand = ''
      mkdir -p $out/share/www/cinny
      cp -r $src/* $out/share/www/cinny
    '';
    passthru.webroot = "${app}/share/www/cinny";
  };
in app
