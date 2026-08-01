{
  xdg.mime = let
    browser = "org.chromium.Chromium.desktop";
    epiphany = "org.gnome.Epiphany.desktop";
  in {
    defaultApplications = {
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
      "text/html" = epiphany;
      "application/xhtml+xml" = epiphany;
      "audio/*" = "io.bassi.Amberol.desktop";
      "image/*" = "org.gnome.Loupe.desktop";
    };
  };
}
