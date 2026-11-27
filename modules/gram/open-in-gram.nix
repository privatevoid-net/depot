{ lib, pkgs, ... }:

let
  script = pkgs.writers.writePython3 "open-project-in-gram" {
    flakeIgnore = [ "E501" ];
  } (pkgs.replaceVars ./open-project-in-gram.py {
    zenity = lib.getExe pkgs.zenity;
  });

  openInGram = pkgs.makeDesktopItem {
    name = "cooking.schizo.OpenInGram";
    desktopName = "Open project in Gram";
    noDisplay = true;
    mimeTypes = [
      "x-scheme-handler/vscode"
      "x-scheme-handler/vscodium"
      "x-scheme-handler/ghapp"
    ];
    icon = "app.liten.Gram";
    startupNotify = false;
    tryExec = "gram";
    exec = "${script} %u";
  };
in

{
  environment.systemPackages = [ openInGram ];
}
