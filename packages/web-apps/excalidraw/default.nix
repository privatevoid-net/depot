{
  lib,
  fetchFromGitHub,
  fetchYarnDeps,
  mkNpinsSource,
  nodejs,
  pins,
  stdenv,
  yarnBuildHook,
  yarnConfigHook
}:

let
  inherit (pins) excalidraw;

  app = stdenv.mkDerivation rec {
    pname = "excalidraw";
    version = "0.0.0+${builtins.substring 0 7 excalidraw.revision}";

    REACT_APP_DISABLE_SENTRY = "true";
    REACT_APP_FIREBASE_CONFIG = "";
    REACT_APP_GOOGLE_ANALYTICS_ID = "";

    src = mkNpinsSource excalidraw;

    packageJSON = "${excalidraw}/package.json";

    nativeBuildInputs = [
      yarnConfigHook
      yarnBuildHook
      nodejs
    ];

    offlineCache = fetchYarnDeps {
      name = "excalidraw-yarn-cache-${builtins.hashString "sha256" (builtins.readFile "${excalidraw}/yarn.lock")}";
      yarnLock = src + "/yarn.lock";
      hash = "sha256-v2ycGVq0q/Rs3UaSh/mExmf3ehWaCQg+CeWS2qQ/674=";
    };

    installPhase = ''
      distRoot=$out/share/www
      dist=$distRoot/excalidraw
      mkdir -p $distRoot
      mv excalidraw-app/build $dist
      find $dist -type f -name "*.map" -delete
    '';

    passthru.webroot = "${app}/share/www/excalidraw";

    meta = with lib; {
      description = "Virtual whiteboard for sketching hand-drawn like diagrams";
      homepage = "https://github.com/excalidraw/excalidraw";
      changelog = "https://github.com/excalidraw/excalidraw/blob/${src.rev}/CHANGELOG.md";
      license = licenses.mit;
    };
  };
in app
