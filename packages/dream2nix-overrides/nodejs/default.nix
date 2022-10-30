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

  uptime-kuma.runtime-bugfixes = {
    patches = [
      ./uptime-kuma/chmod-database.patch
      ./uptime-kuma/data-dir-concat-with-slash.patch
    ];
  };

  uptime-kuma.build = {
    # HACK: rollup.js is garbage and expects the contents of node_modules to not be symlinks
    # obey its wishes by copying dependencies into place
    preBuild = ''
      cp -r node_modules $NIX_BUILD_TOP/node_modules_saved
      find node_modules node_modules/@* -maxdepth 1 -type l -exec \
        bash -c 'LOC=$(readlink -f {}); echo unsymlinking: {}; rm {}; cp -r $LOC {}' \;

      chmod +w -R node_modules
      find node_modules -mindepth 2 -name node_modules | xargs rm -rf
    '';

    preInstall = ''
      echo restoring original node_modules directory
      rm -rf node_modules
      mv $NIX_BUILD_TOP/node_modules_saved node_modules
    '';

    # unfortunately, upstream's installMethod = copy results in bloat, so we can't use it
    installMethod = "symlink";

    postInstall = ''
      makeWrapper $(command -v node) $out/bin/uptime-kuma \
        --add-flags "server/server.js" \
        --run "cd $out/lib/node_modules/uptime-kuma" \
        --set NODE_PATH "$out/lib/node_modules/uptime-kuma/node_modules"
    '';
  };

  "@louislam/sqlite3".closure-bloat = {
    postFixup = ''
      rm -rf build-*/
      find $out -type d -name '*-node-addon-api-*' -print0 | xargs -0 rm -rf
    '';
  };
}
