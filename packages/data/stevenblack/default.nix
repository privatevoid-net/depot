{ stdenvNoCC, npins, pins }:

let
  src = npins.mkSource pins.stevenblack;
in

stdenvNoCC.mkDerivation {
  pname = "stevenblack-hosts";
  inherit (pins.stevenblack) version;
  buildCommand = ''
    cp ${src}/hosts $out
  '';
}
