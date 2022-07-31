{ lib, pkgs, self', ... }:
let
  theme = self'.packages.gohugo-theme-ananke;
  themeName = "ananke";

  themesDir = "${theme}/share/hugo/themes";

  configFile = pkgs.writeText "hugo-config.json" (builtins.toJSON {
    title = "Private Void | Zero-maintenance perfection";
    baseURL = "https://www.privatevoid.net/";
    languageCode = "en-us";
    theme = themeName;
    inherit themesDir;
  });
  hugoArgs = [
    "--config" configFile
  ];
in
{
  projectShells.landing = {
    commands.hugo = {
      help = pkgs.hugo.meta.description;
      command = "exec ${pkgs.hugo}/bin/hugo ${lib.concatStringsSep " " hugoArgs} \"$@\"";
    };
  };
}
