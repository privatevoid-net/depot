{ config, depot, ... }:
let
  inherit (depot.reflection) interfaces;
in
{
  imports = [
    ./port-forward.nix
    ./peering.nix
  ];

  networking.nat = {
    enable = true;
    externalInterface = interfaces.primary.link;
    internalIPs = [
      "10.10.0.0/16"
    ];
  };

  networking.interfaces.${interfaces.vstub.link} = {
    virtual = true;
    ipv4.addresses = [
      {
        address = interfaces.vstub.addr;
        prefixLength = 32;
      }
    ];
  };
}
