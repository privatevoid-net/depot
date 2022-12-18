{ config, dependencySets, lib, ... }:

let
  inherit (config) deps;

  withDistOutput = lib.elem config.format [
    "pyproject"
    "setuptools"
    "flit"
    "wheel"
  ];

  hasPyproject = config.format == "pyproject" && config.pyprojectToml != null;

  pyproject = if hasPyproject then
    lib.importTOML config.pyprojectToml
  else
    null;
in

{
  pname = lib.mkIf hasPyproject (lib.mkDefault pyproject.tool.poetry.name);
  version = lib.mkIf hasPyproject (lib.mkDefault pyproject.tool.poetry.version);

  deps = { pkgs, python3Packages, ... }: {
    inherit (python3Packages)
      python
      wrapPython
      pythonRemoveTestsDirHook
      pythonCatchConflictsHook
      pythonRemoveBinBytecodeHook
      unzip
      setuptoolsBuildHook
      flitBuildHook
      pipBuildHook
      wheelUnpackHook
      eggUnpackHook eggBuildHook eggInstallHook
      pipInstallHook
      pythonImportsCheckHook
      pythonNamespacesHook
      pythonOutputDistHook
    ;
    inherit (pkgs)
      ensureNewerSourcesForZipFilesHook
    ;
  };

  nativeBuildInputs = with deps; [
    python
    wrapPython
    ensureNewerSourcesForZipFilesHook
    pythonRemoveTestsDirHook
  ] ++ lib.optionals config.catchConflicts [
    pythonCatchConflictsHook
  ] ++ lib.optionals config.removeBinByteCode [
    pythonRemoveBinBytecodeHook
  ] ++ lib.optionals (lib.hasSuffix "zip" (config.src.name or "")) [
    unzip
  ] ++ lib.optionals (config.format == "setuptools") [
    setuptoolsBuildHook
  ] ++ lib.optionals (config.format == "flit") [
    flitBuildHook
  ] ++ lib.optionals (config.format == "pyproject") [
    pipBuildHook
  ] ++ lib.optionals (config.format == "wheel") [
    wheelUnpackHook
  ] ++ lib.optionals (config.format == "egg") [
    eggUnpackHook eggBuildHook eggInstallHook
  ] ++ lib.optionals (!(config.format == "other") || config.dontUsePipInstall) [
    pipInstallHook
  ] ++ lib.optionals (python.stdenv.buildPlatform == python.stdenv.hostPlatform) [
    # This is a test, however, it should be ran independent of the checkPhase and checkInputs
    pythonImportsCheckHook
  ] ++ lib.optionals (python.pythonAtLeast "3.3") [
    # Optionally enforce PEP420 for python3
    pythonNamespacesHook
  ] ++ lib.optionals withDistOutput [
    pythonOutputDistHook
  ];

  propagatedBuildInputs = with deps; [
    python
  ];

  env = {
    strictDeps = if config.strictDeps == null then false else config.strictDeps;
    LANG = "${if deps.python.stdenv.isDarwin then "en_US" else "C"}.UTF-8";
  };

  doCheck = false;
  doInstallCheck = lib.mkDefault true;
  installCheckInputs = lib.optionals (config.format == "setuptools") [
    deps.setuptoolsCheckHook
  ];

  postFixup = lib.mkBefore (lib.optionalString (!config.dontWrapPythonPrograms) ''
    wrapPythonPrograms
  '');

  outputs = [ "out" ] ++ lib.optional withDistOutput "dist";
}
