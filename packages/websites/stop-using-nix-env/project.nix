{ pkgs, ... }:

{
  packages.stop-using-nix-env = let
    site = with pkgs; stdenvNoCC.mkDerivation rec {
      pname = "stop-using-nix-env";
      version = "1.1.1";
      src = ./src;
      buildCommand = ''
        install -Dm644 $src/* -t $out/share/www/${pname}
        substituteInPlace $out/share/www/${pname}/index.html \
          --replace '<!-- VERSION -->' 'Version ${version} |'
      '';
      passthru = {
        webroot = "${site}/share/www/${pname}";
      };
    };
  in site;
}
