{ config, lib, depot, ... }:

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
        ./orgs/private-void.nix
      ];
      nixpak = [
        ./common.nix
        ./orgs/nixpak.nix
      ];
      max = [
        ./common.nix
        ./orgs/max.nix
      ];
      hyprspace = [
        ./common.nix
        ./orgs/hyprspace.nix
      ];
    };
  };
  garage = let
    hciAgentKeys = lib.pipe config.services.hercules-ci-multi-agent.nodes [
      (lib.collect lib.isList)
      lib.flatten
      lib.unique
      (map (x: "hci-agent-${x}"))
    ];
  in {
    keys = lib.genAttrs hciAgentKeys (lib.const {});
    buckets.nix-store.allow = lib.genAttrs hciAgentKeys (lib.const [ "read" "write" ]);
  };
}
