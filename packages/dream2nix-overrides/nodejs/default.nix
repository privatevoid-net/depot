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
      lib.assertMsg (lib.versionAtLeast target.version pkg.version)
      "${pkg.name} has reached the desired version upstream";
      target;

  vips_8_12_2' = pkgs.vips.overrideAttrs (_: {
    version = "8.12.2";
    src = pkgs.fetchFromGitHub {
      owner = "libvips";
      repo = "libvips";
      rev = "v8.12.2";
      sha256 = "sha256-ffDJJWe/SzG+lppXEiyfXXL5KLdZgnMjv1SYnuYnh4c=";
      extraPostFetch = ''
        rm -r $out/test/test-suite/images/
      '';
    };
  });

  vips_8_12_2 = versionGate pkgs.vips vips_8_12_2';
in

{
  sharp.build = with pkgs; {
    nativeBuildInputs = old: old ++ [
      pkg-config
    ];
    buildInputs = old: old ++ [
      vips_8_12_2
    ];
  };
  ghost.build = {
    # zip comes pre-built
    runBuild = "";

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    postInstall = ''
      makeWrapper $(command -v node) $out/bin/ghost \
        --add-flags "index.js" \
        --run "cd $out/lib/node_modules/ghost" \
        --set NODE_PATH "$out/lib/node_modules/ghost/node_modules"
    '';
  };
}
