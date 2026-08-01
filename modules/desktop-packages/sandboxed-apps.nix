{
  security.nixpak.apps = {
    amberol = {};
    buffer = {};
    dialect = {};
    gnome-calculator = {};
    gnome-maps = {};
    ungoogled-chromium.configuration = {
      flatpak = {
        appId = "org.chromium.Chromium";
        desktopFile = "chromium-browser.desktop";
      };
      bubblewrap.bind.ro = [
        "/etc/chromium"
        "/etc/static/chromium"
        "/run/current-system/sw/share/chromium/extensions"
      ];
      dbus.policies = {
        "org.freedesktop.Notifications" = "talk";
      };
    };
  };
}
