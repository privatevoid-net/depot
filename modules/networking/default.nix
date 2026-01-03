{ config, lib, ... }:
let
  inherit (config.reflection) interfaces;
in
{
  networking.interfaces = lib.mkIf (interfaces ? vstub) {
    ${interfaces.vstub.link} = {
      virtual = true;
      ipv4.addresses = [
        {
          address = interfaces.vstub.addr;
          prefixLength = 32;
        }
      ];
    };
  };

  networking.defaultGateway.interface = interfaces.primary.link;
}
