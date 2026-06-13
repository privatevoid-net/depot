{ config, lib, pkgs, ... }:

let
  inherit (config.desktop) hiddenApps;

  hiddenDesktopFile = pkgs.writeText "hidden.desktop" ''
    [Desktop Entry]
    Hidden=true
    NoDisplay=true
  '';
  hiddenAppsPackage = pkgs.runCommandLocal "hidden-apps" {} ''
    mkdir -p $out/applications
    for app in ${lib.escapeShellArgs hiddenApps}; do
      ln -sf ${hiddenDesktopFile} "$out/applications/$app"
    done
  '';
in

{
  options.desktop = {
    hiddenApps = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
    };
  };
  config = lib.mkIf (hiddenApps != []) {
    environment.sessionVariables.XDG_DATA_DIRS = lib.mkBefore [ hiddenAppsPackage ];
  };
}
