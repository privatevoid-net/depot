{
  lib,
  pkgs,

  # dream2nix
  satisfiesSemver,
  ...
}: 

let
  versionGate = pkg: target:
    assert
      lib.assertMsg (lib.versionOlder pkg.version target.version)
      "${pkg.name} has reached the desired version upstream";
      target;
in

{
  excalidraw.build = {
    REACT_APP_DISABLE_SENTRY = "true";
    REACT_APP_FIREBASE_CONFIG = "";
    REACT_APP_GOOGLE_ANALYTICS_ID = "";
    

    nativeBuildInputs = [ pkgs.yarn ];

    installPhase = ''
      distRoot=$out/share/www
      dist=$distRoot/excalidraw
      mkdir -p $distRoot
      mv $nodeModules/excalidraw/build $dist
      find $dist -type f -name "*.map" -delete
    '';

    passthru.webPath = "share/www/excalidraw";
  };

  sharp.build = with pkgs; {
    nativeBuildInputs = old: old ++ [
      pkg-config
    ];
    buildInputs = old: old ++ [
      vips
    ];
  };

  puppeteer.dummy-build = {
    # HACK: doesn't build, but we don't need it anywhere
    configurePhase = "exit 0";
  };
}
