{ stdenvNoCC, fetchzip, pins }:

let
  inherit (pins) cinny;
  repo = cinny.repository;

  app = stdenvNoCC.mkDerivation rec {
    pname = "cinny-bin";
    version = builtins.substring 1 (-1) cinny.version;

    src = fetchzip {
      name = "cinny-tarball-${version}";
      url = "https://github.com/${repo.owner}/${repo.repo}/releases/download/${cinny.version}/cinny-${cinny.version}.tar.gz";
      sha256 = "sha256-80mIlmX6ZKB3c6aJR1j1Pm0WoJ2rJ8FeF6be0jUlJb8=";
    };

    buildCommand = ''
      mkdir -p $out/share/www/cinny
      cp -r $src/* $out/share/www/cinny
    '';
    passthru.webroot = "${app}/share/www/cinny";
  };
in app
