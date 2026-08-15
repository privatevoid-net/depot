{ lib, pkgs, ... }:

let
  script = pkgs.writers.writePython3 "open-project-in-zedless" {
    flakeIgnore = [ "E501" ];
  } (pkgs.replaceVars ./open-project-in-zedless.py {
    zenity = lib.getExe pkgs.zenity;
  });

  openInBlackBox = pkgs.makeDesktopItem {
    name = "cooking.schizo.OpenInZedless";
    desktopName = "Open project in Zedless";
    noDisplay = true;
    mimeTypes = [
      "x-scheme-handler/vscode"
      "x-scheme-handler/vscodium"
      "x-scheme-handler/ghapp"
    ];
    icon = "zedless";
    startupNotify = false;
    tryExec = "zedless";
    exec = "${script} %u";
  };
in

{
  environment.systemPackages = [ openInBlackBox ];
}
