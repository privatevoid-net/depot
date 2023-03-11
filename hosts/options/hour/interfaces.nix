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
