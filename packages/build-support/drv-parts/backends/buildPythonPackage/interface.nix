{ lib, ... }:
with lib;

let
  flag = default: description: mkOption {
    inherit description default;
    type = types.bool;
  };
in

{
  options = {
    format = mkOption {
      description = "Python package source format";
      type = types.enum [
        "setuptools"
        "pyproject"
        "flit"
        "wheel"
        "other"
      ];
    };
    catchConflicts = flag true "If true, abort package build if a package name appears more than once in dependency tree.";
    dontWrapPythonPrograms = flag false "Skip wrapping of Python programs.";
    removeBinByteCode = flag true "Remove bytecode from /bin. Bytecode is only created when the filenames end with .py.";
  };
}
