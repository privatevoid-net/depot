{ config, lib, name, ... }:

with builtins;
with lib;

let
  cfg = config;

  portHash = flip pipe [
    (hashString "md5")
    (substring 0 7)
    (hash: (fromTOML "v=0x${hash}").v)
    (flip mod cfg.reservedPorts.amount)
    (add cfg.reservedPorts.start)
  ];
in

{
  options = {
    ipv4 = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "The IPv4 address.";
    };
    hostname = mkOption {
      type = types.str;
      description = "The hostname.";
    };

    port = mkOption {
      type = types.int;
      description = "The TCP or UDP port.";
    };
    portStr = mkOption {
      type = types.str;
      description = "The TCP or UDP port, as a string.";
    };
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

    protocol = mkOption {
      type = types.str;
      description = "The protocol in URL scheme name format.";
    };
    path = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "The resource path.";
    };
    url = mkOption {
      type = types.str;
      description = "The URL.";
    };
    tuple = mkOption {
      type = types.str;
      description = "The hostname:port tuple.";
    };
    extra = mkOption {
      type = types.attrs;
      description = "Arbitrary extra data.";
    };
  };
  config = mkIf true {
    hostname = mkDefault cfg.ipv4;
    port = mkDefault (portHash "${cfg.hostname}:${name}");
    portStr = toString cfg.port;
    tuple = "${cfg.hostname}:${cfg.portStr}";
    url = "${cfg.protocol}://${cfg.tuple}${if cfg.path == null then "" else cfg.path}";
  };
}
