{ config, lib, ... }:
let
  inherit (config.reflection) interfaces;
in
{
  networking = {
    useDHCP = false;
    dhcpcd.enable = false;
    defaultGateway = {
      address = interfaces.primary.gatewayAddr;
      interface = interfaces.primary.link;
    };
    interfaces = lib.mkMerge [
      {
        ${interfaces.primary.link} = {
          ipv4 = {
            addresses = [
              {
                address = interfaces.primary.addr;
                inherit (interfaces.primary) prefixLength;
              }
            ];
            routes = lib.mkIf (interfaces.primary.prefixLength == 32) [
              {
                address = interfaces.primary.gatewayAddr;
                prefixLength = 32;
              }
            ];
          };
        };
      }
      (lib.mkIf (interfaces ? vstub) {
        ${interfaces.vstub.link} = {
          virtual = true;
          ipv4.addresses = [
            {
              address = interfaces.vstub.addr;
              prefixLength = 32;
            }
          ];
        };
      })
    ];
  };
}
