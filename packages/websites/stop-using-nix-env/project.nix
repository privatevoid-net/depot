{ pkgs, ... }:

{
  packages.stop-using-nix-env = let
    site = with pkgs; stdenvNoCC.mkDerivation rec {
      name = "stop-using-nix-env";
      version = "1.1.1";
      src = ./src;
      buildCommand = ''
        install -Dm644 $src/* -t $out/share/www/${name}
        substituteInPlace $out/share/www/${name}/index.html \
          --replace '<!-- VERSION -->' 'Version ${version} |'
      '';
      passthru = {
        webroot = "${site}/share/www/${name}";
      };
    };
  in site;
}
