{
  lib,
  buildNpmPackage,
  fetchFromGitea,
  makeWrapper,
}:

buildNpmPackage rec {
  pname = "out-of-your-element";
  version = "3.0";

  src = fetchFromGitea {
    domain = "gitdab.com";
    owner = "cadence";
    repo = "out-of-your-element";
    tag = "v${version}";
    hash = "sha256-fPAJuWVclFMslc0SaaCwcQTuD1oJE+AbPU9FDmUtuns=";
  };

  npmDepsHash = "sha256-pSyEhTnBY++FETfrkAy7wXqu36u8nD6pUMuOfl2dII4=";
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
