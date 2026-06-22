{ pkgs, ... }:

let
  soundTheme = pkgs.runCommand "custom-sound-theme" { } ''
    themeDir=$out/share/sounds/custom
    mkdir -p $themeDir
    echo > $themeDir/index.theme '
    [Sound Theme]
    Name=Custom
    Inherits=freedesktop
    Directories=.
    '
    ln -s ${pkgs.gnome-control-center}/share/sounds/gnome/default/alerts/hum.ogg $themeDir/bell-terminal.ogg
    ln -s ${pkgs.gnome-control-center}/share/sounds/gnome/default/alerts/hum.ogg $themeDir/bell-window-system.ogg
  '';
in

{
  environment.systemPackages = [
    soundTheme
  ];

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/desktop/sound" = {
          theme-name = "custom";
        };
      };
    }
  ];
}
