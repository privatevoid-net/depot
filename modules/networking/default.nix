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
    interfaces = {
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
    };
  };
  systemd.network = lib.mkMerge [
    { enable = !config.boot.isContainer; }
    (lib.mkIf (interfaces ? vstub) {
      netdevs."30-vstub" = {
        netdevConfig = {
          Name = "vstub";
          Kind = "dummy";
        };
      };
      networks."30-vstub" = {
        matchConfig.Name = interfaces.vstub.link;
        networkConfig = {
          DHCP = false;
          ConfigureWithoutCarrier = true;
          Address = "${interfaces.vstub.addr}/32";
        };
      };
    })
  ];
}
