{ inputs, ... }: 

{
  perSystem = { config, drv-backends, lib, pkgs, ... }: let
    deps = with config.drv-parts.dependencySets.python3Packages; [
      poetry-core
      requests-unixsocket
      py-multibase
      py-multiaddr
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
    drvs.reflex-cache = { dependencySets, ... }: {
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