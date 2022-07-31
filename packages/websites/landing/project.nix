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
  hugoArgsStr = lib.concatStringsSep " " hugoArgs;
in
{
  projectShells.landing = {
    commands.hugo = {
      help = pkgs.hugo.meta.description;
      command = "exec ${pkgs.hugo}/bin/hugo ${hugoArgsStr} \"$@\"";
    };
  };

  packages.landing = with pkgs; let
    site = stdenvNoCC.mkDerivation rec {
      pname = "private-void-landing-page";
      version = "0.0.0";
      src = ./.;
      nativeBuildInputs = [
        hugo
      ];
      buildCommand = ''
        unpackPhase
        mkdir -p $out/share/www
        hugo ${hugoArgsStr} -s $sourceRoot -d $out/share/www/${pname}
      '';
      passthru.webroot = "${site}/share/www/${site.pname}";
    };
  in site;
}
