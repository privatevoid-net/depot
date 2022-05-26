{ runCommandLocal, pins }:

runCommandLocal "stevenblack-hosts-${pins.stevenblack.version}" {} ''
  cp ${pins.stevenblack}/hosts $out
''
