{ inputs, ... }: 

{
  perSystem = { config, drv-backends, lib, pkgs, ... }: let
    deps = with config.drv-parts.packageSets.python3Packages; [
      poetry-core
      requests-unixsocket
      py-multibase
      (py-multiaddr.overrideAttrs rec {
        version = "0.0.9";
        src = pkgs.fetchFromGitHub {
          owner = "multiformats";
          repo = "py-multiaddr";
          tag = "v${version}";
          hash = "sha256-cGM7iYQPP+UOkbTxRhzuED0pkcydFCO8vpx9wTc0/HI=";
        };
      })
    ];

    pythonForDev = pkgs.python3.withPackages (lib.const deps);
  in
  {
    projectShells.reflex-cache = {
      tools = [
        pythonForDev
      ];
      env.PYTHON = pythonForDev.interpreter;
      commands.reflex.command = "${pythonForDev.interpreter} -m reflex_cache.main";
    };
    drvs.reflex-cache = { packageSets, ... }: {
      imports = [
        drv-backends.buildPythonPackage
      ];
      pyprojectToml = ./pyproject.toml;

      mkDerivation = {
        propagatedBuildInputs = deps;

        src = with inputs.nix-filter.lib; filter {
          root = ./.;
          include = [
            "pyproject.toml"
            (inDirectory "reflex_cache")
          ];
        };
      };
    };
  };
}