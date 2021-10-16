# internal interface
{ toolsets }:
# external interface
{ lib ? null, ... }:
let
  tools = (self: {

    all = {};

    ipv4.all = {};

    ipv4.internal = {
      addr = "10.0.0.0/8";
      vpn = {
        addr = "10.100.0.0/16";
      };
    };

  }) tools;
in tools
