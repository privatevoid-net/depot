{ name, config, lib, ... }:
with lib;

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
    nixos = mkOption {
      description = "NixOS configurations per node group.";
      type = with types; attrs;
      default = {};
    };
  };
}
