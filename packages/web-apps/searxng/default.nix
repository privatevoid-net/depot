{ lib, nixosTests, python3, python3Packages, npins, pins }:

let
  pin = pins.searxng;
  repo = pin.repository;
in with python3Packages;

toPythonModule (buildPythonApplication rec {
  pname = "searxng";
  version = "1.0.0pre_${builtins.substring 0 7 pin.revision}";

  src = npins.mkSource pins.searxng;

  postPatch = ''
    sed -i \
      -e 's/==.*$//' \
      requirements.txt
    cat >searx/version_frozen.py <<EOF
    VERSION_STRING="${version}"
    VERSION_TAG="1.0.0"
    GIT_URL="https://github.com/${repo.owner}/${repo.repo}"
    GIT_BRANCH="${pin.branch}"
    DOCKER_TAG="none"
    EOF
  '';

  preBuild = ''
    export SEARX_DEBUG="true";
  '';

  propagatedBuildInputs = [
    Babel
    certifi
    python-dateutil
    flask
    flaskbabel
    brotli
    jinja2
    langdetect
    lxml
    h2
    pygments
    pyyaml
    redis
    uvloop
    setproctitle
    httpx
    httpx-socks
    markdown-it-py
    fasttext-predict
    pybind11
  ];

  # tests try to connect to network
  doCheck = false;

  pythonImportsCheck = [ "searx" ];

  postInstall = ''
    # Create a symlink for easier access to static data
    mkdir -p $out/share
    ln -s ../${python3.sitePackages}/searx/static $out/share/
  '';
})
