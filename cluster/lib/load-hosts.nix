{ config, lib, ... }:
let
  hosts = import ../../hosts;
  self = hosts.${config.vars.hostName};
  others = lib.filterAttrs (_: host: host != self) hosts;
in
{
  config.vars.hosts = hosts // { inherit self others; };
}
