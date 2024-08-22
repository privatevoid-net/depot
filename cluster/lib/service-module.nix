{ config, lib, name, ... }:
with lib;

let
  filterGroup = group: hostName: builtins.filter (x: x != hostName) group;
  serviceName = name;
in

{
  imports = [
    ./services/secrets.nix
  ];

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
      type = with types; lazyAttrsOf (oneOf [ str (listOf str) ]);
      default = [];
    };
    otherNodes = mkOption {
      description = "Other nodes in the group.";
      type = with types; lazyAttrsOf (functionTo (listOf str));
      default = [];
    };
    nixos = mkOption {
      description = "NixOS configurations per node group.";
      type = with types; attrs;
      default = {};
    };
    meshLinks = mkOption {
      description = "Create host links on the mesh network.";
      type = types.attrsOf (types.attrsOf (types.submodule {
        options = {
          link = mkOption {
            type = types.deferredModule;
            default = {};
          };
        };
      }));
      default = {};
    };
    simulacrum = {
      enable = mkEnableOption "testing this service in the Simulacrum";
      deps = mkOption {
        description = "Other services to include.";
        type = with types; listOf str;
        default = [];
      };
      settings = mkOption {
        description = "NixOS test configuration.";
        type = types.deferredModule;
        default = {};
      };
      augments = mkOption {
        description = "Cluster augments (will be propagated).";
        type = types.deferredModule;
        default = {};
      };
    };
  };
  config.otherNodes = builtins.mapAttrs (const filterGroup) config.nodes;
}
