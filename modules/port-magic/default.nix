{ config, lib, ... }:

with lib;    

{
  options.links = mkOption {
    type = types.attrsOf (types.submodule ./link.nix);
    description = "Port Magic links.";
    default = {};
  };
}
