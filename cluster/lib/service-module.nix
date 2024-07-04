{ config, lib, name, ... }:
with lib;

let
  filterGroup = group: hostName: builtins.filter (x: x != hostName) group;
  serviceName = name;
in

{
  options = {
    nodes = mkOption {
      description = ''
        Groups of worker machines to run this service on.
        Allows for arbitrary multi-node constructs, such as:
          * 1 master, N workers
          * N masters, M workers
          * N nodes
          * 1 node
          * X evaluators, Y smallBuilders, Z bigBuilders
        etc.
      '';
      type = with types; attrsOf (oneOf [ str (listOf str) ]);
      default = [];
    };
    otherNodes = mkOption {
      description = "Other nodes in the group.";
      type = with types; attrsOf (functionTo (listOf str));
      default = [];
    };
    nixos = mkOption {
      description = "NixOS configurations per node group.";
      type = with types; attrs;
      default = {};
    };
    meshLinks = mkOption {
      description = "Create host links on the mesh network.";
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          name = mkOption {
            type = types.str;
            default = "${serviceName}-${name}";
          };
          link = mkOption {
            type = types.deferredModule;
            default = {};
          };
        };
      }));
      default = {};
    };
  };
  config.otherNodes = builtins.mapAttrs (const filterGroup) config.nodes;
}
