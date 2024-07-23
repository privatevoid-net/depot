{ lib, ... }:

{
  perSystem = { config, pkgs, ... }: {
    catalog = lib.mkMerge (lib.mapAttrsToList (name': check: let
      simulacrum = lib.hasPrefix "simulacrum-" name';
      name = lib.removePrefix "simulacrum-" name';
      baseAttrPath = if simulacrum then
        [ "cluster" "simulacrum" ]
      else
        [ "depot" "checks" ];
    in lib.setAttrByPath (baseAttrPath ++ [ name ]) {
      description = if simulacrum then
        "Simulacrum Test: ${name}"
      else
        "NixOS Test: ${name}";
      actions = {
        build = {
          description = "Build this check.";
          command = "nix build -L --no-link '${builtins.unsafeDiscardStringContext check.drvPath}^*'";
        };
        runInteractive = {
          description = "Run interactive driver.";
          command = if simulacrum then
            "${pkgs.bubblewrap}/bin/bwrap --unshare-all --bind / / --dev-bind /dev /dev ${lib.getExe check.driverInteractive}"
          else
            lib.getExe check.driverInteractive;
        };
      };
    }) config.checks);
  };
}
