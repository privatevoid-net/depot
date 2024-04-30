{ depot, ... }:
let
  inherit (depot.reflection) interfaces;
in
{
  imports = [
    ./port-forward.nix
  ];

  networking.nat = {
    enable = true;
    externalInterface = interfaces.primary.link;
    internalIPs = [
      "10.10.0.0/16"
    ];
  };
}
