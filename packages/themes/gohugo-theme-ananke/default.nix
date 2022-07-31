{ stdenvNoCC, npins, pins }:

stdenvNoCC.mkDerivation {
  pname = "gohugo-theme-ananke";
  version = builtins.substring 1 (-1) pins.gohugo-theme-ananke.version;
  src = npins.mkSource pins.gohugo-theme-ananke;
  buildCommand = ''
    mkdir -p $out/share/hugo/themes
    cp -r $src $out/share/hugo/themes/ananke
  '';
}
