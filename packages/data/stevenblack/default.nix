{ stdenvNoCC, npins, pins }:

let
  src = npins.mkSource pins.stevenblack-hosts;
in

stdenvNoCC.mkDerivation {
  pname = "stevenblack-hosts";
  inherit (pins.stevenblack-hosts) version;
  buildCommand = ''
    cp ${src}/hosts $out
  '';
}
