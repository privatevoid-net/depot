{ lib, fetchAsset, runCommandNoCC }:

rootDir: let

  prefix = ((toString rootDir) + "/");

  files = lib.filesystem.listFilesRecursive rootDir;

  hydrate = index: fetchAsset { inherit index; };

  isDvc = lib.strings.hasSuffix ".dvc";

  relative = file: lib.strings.removePrefix prefix (toString file);

  files' = builtins.partition isDvc files;

  filesRaw = map relative files'.wrong;

  filesDvc = map (file: rec {
    dvc = hydrate file;
    installPath = (builtins.dirOf (relative file)) + "/${dvc.name}";
  }) files'.right;

  installFile = file: "install -Dm644 ${file} $out/${file}";

  installDvc = dvc: "install -Dm644 ${dvc.dvc} $out/${dvc.installPath}";

in runCommandNoCC (builtins.baseNameOf rootDir) {} ''
  cd ${rootDir}
  mkdir $out
  ${lib.concatStringsSep "\n" (map installFile filesRaw)}
  ${lib.concatStringsSep "\n" (map installDvc filesDvc)}
''
