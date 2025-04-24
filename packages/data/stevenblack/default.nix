{ stdenvNoCC, mkNpinsSource, pins }:

let
  src = mkNpinsSource pins.stevenblack-hosts;
in

stdenvNoCC.mkDerivation {
  pname = "stevenblack-hosts";
  inherit (pins.stevenblack-hosts) version;
  buildCommand = ''
    cp ${src}/hosts $out
  '';
}
