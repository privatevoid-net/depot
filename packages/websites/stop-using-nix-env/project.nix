{ pkgs, ... }:

{
  packages.stop-using-nix-env = let
    site = with pkgs; stdenvNoCC.mkDerivation rec {
      name = "stop-using-nix-env";
      version = "1.1.0";
      src = ./src;
      buildCommand = ''
        install -Dm644 $src/* -t $out/share/www/${name}
      '';
      passthru = {
        webroot = "${site}/share/www/${name}";
      };
    };
  in site;
}
