{ lib, nixosTests, python3, python3Packages, fetchFromGitHub, fetchpatch, pins }:

with python3Packages;

toPythonModule (buildPythonApplication rec {
  pname = "searxng";
  version = "1.0.0pre_${builtins.substring 0 7 pins.searxng.revision}";

  src = pins.searxng;

  postPatch = ''
    sed -i 's/==.*$//' requirements.txt
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
