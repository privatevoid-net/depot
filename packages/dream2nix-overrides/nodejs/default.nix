{
  lib,
  pkgs,

  # dream2nix
  satisfiesSemver,
  ...
}: 

{
  sharp.build = with pkgs; {
    nativeBuildInputs = old: old ++ [
      pkg-config
    ];
    buildInputs = old: old ++ [
      vips
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
