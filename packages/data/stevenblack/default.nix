{ runCommand, npins, pins }:

let
  src = npins.mkSource pins.stevenblack;
in

runCommand "stevenblack-hosts-${pins.stevenblack.version}" {} ''
  cp ${src}/hosts $out
''
