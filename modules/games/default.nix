{ pkgs, ... }:

{
  hardware.graphics.enable32Bit = true;
  programs.steam = {
    enable = true;
    extest.enable = true;
  };
  desktop.appFolders = {
    Games = {
      Categories = [ "Game" ];
      apps = [
        { appId = "steam"; }
      ];
    };
  };

  services.udev.packages = [
    pkgs.steam-devices-udev-rules
  ];
}
