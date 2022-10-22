{ config, lib, ... }:

with lib;

{
  options.hostLinks = mkOption {
    type = types.attrsOf (types.attrsOf (types.submodule ../../modules/port-magic/link.nix));
    description = "Port Magic links, per host.";
    default = {};
  };
}
