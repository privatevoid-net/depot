{ config, lib, ... }:

with builtins;    
with lib;    

let
  cfg = config.reservedPorts;

  portNames = config.reservePortsFor;

  portHash = flip pipe [
    (hashString "sha512")
    stringToCharacters
    (filter (n: match "[0-9]" n == []))
    (map toInt)
    (foldl add 0)
    (mul 1009) # prime number
    (flip mod cfg.amount)
    (add cfg.start)
  ];

  ports = genAttrs portNames portHash;

  portsEnd = cfg.start + cfg.amount;
in {
  options = {
    reservedPorts = {
      amount = mkOption {
        type = types.int;
        default = 10000;
        description = "Amount of ports to reserve at most.";
      };
      start = mkOption {
        type = types.int;
        default = 30000;
        description = "Starting point for reserved ports.";
      };
    };
    reservePortsFor = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of application names for which to automatically reserve ports.";
    };
    ports = mkOption {
      type = types.attrsOf (types.ints.between cfg.start portsEnd);
      default = {};
      description = "Named network ports.";
    };
    portsStr = mkOption {
      readOnly = true;
      type = types.attrsOf types.str;
      description = "Named network ports, as strings.";
    };
  };
  config = lib.mkIf (config.reservePortsFor != []) {
    inherit ports;
    portsStr = mapAttrs (_: toString) ports;
  };
}
