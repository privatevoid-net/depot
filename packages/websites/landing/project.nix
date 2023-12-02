{
  perSystem = { builders, lib, pkgs, self', ... }: let
    configFile = pkgs.writeText "hugo-config.json" (builtins.toJSON {
      title = "Private Void | Zero-maintenance perfection";
      baseURL = "https://www.privatevoid.net/";
      languageCode = "en-us";
      disableKinds = [
        "page"
        "RSS"
        "section"
        "sitemap"
        "taxonomy"
        "taxonomyTerm"
      ];
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
        src = builders.hydrateAssetDirectory ./.;
        nativeBuildInputs = [
          hugo
        ];
        buildCommand = ''
          unpackPhase
          mkdir -p $out/share/www
          hugo ${hugoArgsStr} -s $sourceRoot -d $out/share/www/${pname}
        '';
        passthru = {
          webroot = "${site}/share/www/${site.pname}";
          serve = writeShellScriptBin "serve-site" ''
            command -v xdg-open >/dev/null && xdg-open http://127.0.0.1:1314 || true
            ${darkhttpd}/bin/darkhttpd ${site.webroot} --addr 127.0.0.1 --port 1314
          '';
        };
      };
    in site;
  };
}
