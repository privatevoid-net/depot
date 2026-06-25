{ pkgs, ... }:

{
  environment.smfh.files.".local/share/blackbox/user-keymap.json".source = pkgs.writeText "user-keymap.json" (builtins.toJSON {
    keymap = {
      "win.copy" = [ "<Alt>c" ];
      "win.paste" = [ "<Alt>v" ];
      "win.new_tab" = [ "<Shift><Alt>s" ];
      "app.focus-next-tab" = [ "<Control>Tab" ];
      "app.focus-previous-tab" = [ "<Shift><Control>Tab" ];
      "app.new-window" = [ "<Shift><Control>n" ];
      "win.close-tab" = [ "<Shift><Control>w" ];
      "win.edit_preferences" = [ "<Control>comma" ];
      "win.fullscreen" = [ "F11" ];
      "win.search" = [ "<Alt>f" ];
      "win.show-help-overlay" = [ "<Shift><Control>question" ];
      "win.switch-headerbar-mode" = [ "<Shift><Control>h" ];
      "win.switch-tab-1" = [ "<Alt>1" ];
      "win.switch-tab-2" = [ "<Alt>2" ];
      "win.switch-tab-3" = [ "<Alt>3" ];
      "win.switch-tab-4" = [ "<Alt>4" ];
      "win.switch-tab-5" = [ "<Alt>5" ];
      "win.switch-tab-6" = [ "<Alt>6" ];
      "win.switch-tab-7" = [ "<Alt>7" ];
      "win.switch-tab-8" = [ "<Alt>8" ];
      "win.switch-tab-9" = [ "<Alt>9" ];
      "win.switch-tab-last" = [ "<Alt>0" ];
      "win.zoom-default" = [ "<Shift><Control>parenright" ];
      "win.zoom-in" = [ "<Shift><Control>plus" ];
      "win.zoom-out" = [ "<Control>minus" ];
    };
  });
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        lockAll = true;
        settings = {
          "com/raggesilver/BlackBox" = {
            font = "Monaspace Krypton Semi-Bold 12";
          };
        };
      }
    ];
  };
}
