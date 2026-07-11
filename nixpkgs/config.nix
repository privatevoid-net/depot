{ lib, ... }:

{
  lib.nixpkgs.config = {
    allowInsecurePredicate = package: builtins.elem (lib.getName package) [
      "jitsi-meet"
    ];

    allowUnfreePredicate = package: builtins.elem (lib.getName package) [
      "steam"
      "steam-unwrapped"
    ];
  };
}
