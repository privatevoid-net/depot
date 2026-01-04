{ lib, ... }:
with lib;

let
  interfaceType = types.submodule ({ config, name, ... }: {
    options = {
      addr = mkOption {
        description = "Static IP address assigned to this interface.";
        type = types.str;
      };

      addrPublic = mkOption {
        description = "Static public IP address.";
        type = types.str;
        default = config.addr;
      };

      prefixLength = mkOption {
        description = "Network prefix length.";
        type = types.ints.between 0 32;
        default = 32;
      };

      gatewayAddr = mkOption {
        description = "IP address of the default gateway.";
        type = types.str;
      };

      link = mkOption {
        description = "Interface link name.";
        type = types.str;
        default = name;
      };

      isNat = mkOption {
        description = "Whether the host is behind NAT.";
        type = types.bool;
        default = config.addr != config.addrPublic;
      };
    };
  });
in

{
  options.interfaces = mkOption {
    description = "Network interface information.";
    type = with types; attrsOf interfaceType;
  };
}
