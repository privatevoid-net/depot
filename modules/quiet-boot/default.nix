{ pkgs, ... }:

{
  boot = {
    loader.timeout = 0;
    initrd.verbose = false;
    consoleLogLevel = 0;
    kernelParams = [ "quiet" "udev.log_priority=3" ];
    plymouth = {
      enable = true;
      extraConfig = ''
        DeviceScale=1
      '';
      logo = "${pkgs.nixos-icons}/share/icons/hicolor/96x96/apps/nix-snowflake-white.png";
      font = "${pkgs.adwaita-fonts}/share/fonts/Adwaita/AdwaitaSans-Regular.ttf";
    };
  };
}
