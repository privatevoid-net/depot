{ lib
, fetchFromGitHub
, mkYarnPackage
, fetchYarnDeps
, fixup_yarn_lock
, mkNpinsSource
, pins
}:

let
  inherit (pins) excalidraw;

  app = mkYarnPackage rec {
    pname = "excalidraw";
    version = "0.0.0+${builtins.substring 0 7 excalidraw.revision}";

    REACT_APP_DISABLE_SENTRY = "true";
    REACT_APP_FIREBASE_CONFIG = "";
    REACT_APP_GOOGLE_ANALYTICS_ID = "";

    src = mkNpinsSource excalidraw;

    packageJSON = "${excalidraw}/package.json";

    nativeBuildInputs = [ fixup_yarn_lock ];

    offlineCache = fetchYarnDeps {
      name = "excalidraw-yarn-cache-${builtins.hashString "sha256" (builtins.readFile "${excalidraw}/yarn.lock")}";
      yarnLock = src + "/yarn.lock";
      hash = "sha256-SthMtDZtGGTVRYYRHIPUbQe8ixZ9XSFMAl35MMN4JHY=";
    };

    configurePhase = ''
      runHook preConfigure

      export HOME="$TMPDIR"
      yarn config --offline set yarn-offline-mirror "$offlineCache"
      fixup_yarn_lock yarn.lock
      yarn install --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
      patchShebangs node_modules/

      runHook postConfigure
    '';

    buildPhase = ''
      yarn --offline build:app
    '';

    installPhase = ''
      distRoot=$out/share/www
      dist=$distRoot/excalidraw
      mkdir -p $distRoot
      mv excalidraw-app/build $dist
      find $dist -type f -name "*.map" -delete
    '';

    doDist = false;

    passthru.webroot = "${app}/share/www/excalidraw";

    meta = with lib; {
      description = "Virtual whiteboard for sketching hand-drawn like diagrams";
      homepage = "https://github.com/excalidraw/excalidraw";
      changelog = "https://github.com/excalidraw/excalidraw/blob/${src.rev}/CHANGELOG.md";
      license = licenses.mit;
    };
  };
in app
