{ lib, ... }:

let
  svcs' = builtins.readDir ./services;
  svcs = lib.filterAttrs (_: type: type == "directory") svcs';
  loadService = ent: import ./services/${ent};
in {
  imports = map loadService (builtins.attrNames svcs);
}
