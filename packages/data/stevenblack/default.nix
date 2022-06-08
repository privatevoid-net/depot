{ runCommand, pins }:

runCommand "stevenblack-hosts-${pins.stevenblack.version}" {} ''
  cp ${pins.stevenblack}/hosts $out
''
