{ config, lib, ... }:

{
  services.hercules-ci-multi-agent = {
    nodes = {
      private-void = [ "VEGAS" "prophet" ];
      nixpak = [ "VEGAS" "prophet" ];
      max = [ "VEGAS" "prophet" ];
      hyprspace = [ "VEGAS" "prophet" ];
    };
    nixos = {
      private-void = [
        ./common.nix
        {
          services.hercules-ci-agents.private-void.settings = {
            secretsJsonPath = config.services.hercules-ci-multi-agent.secrets.effectsSecrets.path;
          };
        }
      ];
      nixpak = [
        ./common.nix
      ];
      max = [
        ./common.nix
      ];
      hyprspace = [
        ./common.nix
      ];
    };
    secrets = let
      inherit (config.services.hercules-ci-multi-agent) nodes;
      allNodes = lib.unique (lib.concatLists (lib.attrValues nodes));
    in {
      cacheConfig = {
        nodes = allNodes;
        mode = "0440";
        group = "hercules-ci-agent";
      };
      cacheCredentials = {
        nodes = allNodes;
        shared = false;
        mode = "0440";
        group = "hercules-ci-agent";
      };
      effectsSecrets = {
        nodes = nodes.private-void;
        owner = "hci-private-void";
      };
    } // lib.mapAttrs' (org: nodes: {
      name = "clusterJoinToken-${org}";
      value = {
        inherit nodes;
        shared = false;
        owner = "hci-${org}";
      };
    }) nodes;
  };
  garage = let
    hciAgentKeys = lib.pipe config.services.hercules-ci-multi-agent.nodes [
      (lib.collect lib.isList)
      lib.flatten
      lib.unique
      (map (x: "hci-agent-${x}"))
    ];
  in config.lib.forService "hercules-ci-multi-agent" {
    keys = lib.genAttrs hciAgentKeys (lib.const {});
    buckets.nix-store = {
      allow = lib.genAttrs hciAgentKeys (lib.const [ "read" "write" ]);
      web.enable = true;
    };
  };
}
