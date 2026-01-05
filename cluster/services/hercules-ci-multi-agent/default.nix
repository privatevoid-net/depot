{ config, depot, lib, ... }:

let
  inherit (config.services.hercules-ci-multi-agent) nodes;
  allNodes = lib.unique (lib.concatLists (lib.attrValues nodes));
in
{
  services.hercules-ci-multi-agent = {
    nodes = {
      private-void = [ "VEGAS" "prophet" ];
      nixpak = [ "prophet" "thousandman" ];
      max = [ "VEGAS" "prophet" ];
      hyprspace = [ "prophet" "thousandman" ];
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
    secrets = {
      cacheSigningKey = {
        nodes = allNodes;
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
  hostLinks = lib.genAttrs allNodes (host: {
    builderCache = rec {
      hostname = "${lib.toLower host}.builder-cache.${depot.lib.meta.domain}";
      tuple = lib.mkForce hostname;
      protocol = "https";
    };
  });
  dns = config.lib.forService "hercules-ci-multi-agent" {
    records = lib.listToAttrs (map (host: lib.nameValuePair "${lib.toLower host}.builder-cache" {
      target = [ depot.hours.${host}.interfaces.primary.addrPublic ];
    }) allNodes);
  };
  garage = let
    hciAgentKeys = map (x: "hci-agent-${x}") allNodes;
  in config.lib.forService "hercules-ci-multi-agent" {
    keys = lib.genAttrs hciAgentKeys (lib.const {});
    buckets.nix-store = {
      allow = lib.genAttrs hciAgentKeys (lib.const [ "read" "write" ]);
      web.enable = true;
    };
  };
  attic = config.lib.forService "hercules-ci-agent" {
    tokens.uploadToken = {
      push = [ "nix-store" ];
      locksmith.nodes = allNodes;
    };
  };
}
