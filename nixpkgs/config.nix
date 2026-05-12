{ lib, ... }:

{
  lib.nixpkgs.config = {
    allowInsecurePredicate = package: builtins.elem (lib.getName package) [
      "jitsi-meet"
    ];
  };
}
