{ lib, ... }:

{
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        lockAll = true;
        settings = with lib.gvariant; {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            font-name = "Adwaita Sans 11";
            document-font-name = "Adwaita Sans 12";
            monospace-font-name = "Monaspace Krypton Semi-Bold 12";
          };
          "org/gnome/desktop/wm/keybindings" = {
            close = ["<Super>q"];
            cycle-windows = mkEmptyArray type.string;
            cycle-windows-backward = mkEmptyArray type.string;
            minimize = mkEmptyArray type.string;
            panel-main-menu = mkEmptyArray type.string;
            panel-run-dialog = ["<Shift><Alt>space"];
            raise-or-lower = ["<Super>h"];
            switch-group = mkEmptyArray type.string;
            switch-group-backward = mkEmptyArray type.string;
            switch-panels = mkEmptyArray type.string;
            switch-panels-backward = mkEmptyArray type.string;
            switch-applications = mkEmptyArray type.string;
            switch-applications-backward = mkEmptyArray type.string;
            switch-windows = ["<Super>Tab" "<Alt>Tab"];
            switch-windows-backward = ["<Shift><Super>Tab" "<Shift><Alt>Tab"];
            toggle-fullscreen = ["<Alt><Super>f"];
          };
          "org/gnome/settings-daemon/plugins/media-keys" = {
            control-center = ["<Alt><Super>Return"];
            eject = ["<Shift><Alt>Return"];
            email = ["<Super>m"];
            home = ["<Super>f"];
            www = ["<Super>w"];
            media = ["<Super>AudioPlay"];
            mic-mute = ["<Super>AudioMute"];
            on-screen-keyboard = ["<Alt><Super>k"];
            play = mkEmptyArray type.string;
            window-screenshot-clip = ["<Super>Print"];
            custom-keybindings = map (x: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/${x}/")
            ["open-terminal" "sysmon-de" "sysmon-en"];
          };
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/open-terminal" = {
            binding = "<Super>Return";
            command = "systemd-run --user --scope blackbox";
            name = "Launch Terminal";
          };
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/sysmon-de" = {
            binding = "<Super>y";
            command = "systemd-run --user --scope gnome-system-monitor";
            name = "Launch System Monitor";
          };
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/sysmon-en" = {
            binding = "<Super>z";
            command = "systemd-run --user --scope gnome-system-monitor";
            name = "Launch System Monitor";
          };
          "org/gnome/desktop/input-sources" = {
            xkb-options = [
              "terminate:ctrl_alt_bksp"
              "lv3:ralt_switch"
              "shift:both_capslock_cancel"
              "caps:ctrl_modifier"
            ];
          };
          "org/gnome/desktop/peripherals/touchpad" = {
            natural-scroll = false;
          };
          "org/gnome/shell".app-picker-layout = mkEmptyArray type.string;
        };
      }
    ];
  };
}
