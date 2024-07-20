{ config, ... }:
let
  inherit (config.reflection) interfaces;
in
{
  networking.nat = {
    enable = true;
    externalInterface = interfaces.primary.link;
    internalIPs = [
      "10.10.0.0/16"
    ];
  };
}
