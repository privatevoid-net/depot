{
  lib,
  buildNpmPackage,
  fetchFromGitea,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "out-of-your-element";
  version = "3.1+unstable";

  src = fetchFromGitea {
    domain = "gitdab.com";
    owner = "cadence";
    repo = "out-of-your-element";
    rev = "9a33ba3ed2d4bdfc88d31a9199f03bc2405bd0d1";
    hash = "sha256-0APRIMqrQQFdhnljW7qyjuJpmtdxGgeDtOCJB3V4CzY=";
  };

  npmDepsHash = "sha256-HNHEGez8X7CsoGYXqzB49o1pcCImfmGYIw9QKF2SbHo=";
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  # make the absolutely abhorrent error handling just a tiny bit more useful
  postPatch = ''
    substituteInPlace src/matrix/read-registration.js \
      --replace-fail 'catch (e) {}' 'catch (e) { console.log(e); }'
  '';

  postInstall = ''
    mkdir $out/bin
    chmod +x $out/lib/node_modules/out-of-your-element/scripts/setup.js
    makeWrapper $out/lib/node_modules/out-of-your-element/start.js $out/bin/out-of-your-element \
      --set NODE_PATH $out/lib/node_modules/out-of-your-element/node_modules
    makeWrapper $out/lib/node_modules/out-of-your-element/scripts/setup.js $out/bin/out-of-your-element-setup \
      --set NODE_PATH $out/lib/node_modules/out-of-your-element/node_modules
  '';

  meta = {
    homepage = "https://gitdab.com/cadence/out-of-your-element";
    license = lib.licenses.agpl3Only;
    mainProgram = "out-of-your-element";
    platforms = lib.platforms.all;
  };
}
