{ pkgs, ... }:

let
  openInBlackBox = pkgs.makeDesktopItem {
    name = "cooking.schizo.OpenInBlackBox";
    desktopName = "Black Box";
    noDisplay = true;
    mimeTypes = [ "inode/directory" ];
    icon = "com.raggesilver.BlackBox";
    startupNotify = false;
    tryExec = "blackbox";
    exec = "blackbox -w %f";
  };
in

{
  environment.systemPackages = [ openInBlackBox ];
}
