{ config, lib, ... }:

let
  inherit (config) cluster flake;
in

{
  perSystem = { config, pkgs, ... }: {
    catalog.cluster = {
      services = lib.mapAttrs (name: svc: {
        description = "Cluster service: ${name}";
        actions = let
          mkDeployAction = { description, agents }: {
            inherit description;
            packages = [
              config.packages.cachix
              pkgs.tmux
            ];
            command = let
              cachixDeployJson = pkgs.writeText "cachix-deploy.json" (builtins.toJSON {
                agents = lib.genAttrs agents (name: builtins.unsafeDiscardStringContext flake.nixosConfigurations.${name}.config.system.build.toplevel);
              });
            in ''
              set -e
              echo building ${toString (lib.length agents)} configurations in parallel
              tmux new-session ${lib.concatStringsSep " split-window " (
                map (host: let
                  drvPath = builtins.unsafeDiscardStringContext flake.nixosConfigurations.${host}.config.system.build.toplevel.drvPath;
                in '' 'echo building configuration for ${host}; nix build -L --no-link --store "ssh-ng://${host}" --eval-store auto "${drvPath}^*"'\; '') agents
              )} select-layout even-vertical

              source ~/.config/cachix/deploy
              cachix deploy activate ${cachixDeployJson}
              echo
            '';
          };
        in {
          deployAll = mkDeployAction {
            description = "Deploy ALL groups of this service.";
            agents = lib.unique (lib.concatLists (lib.attrValues svc.nodes));
          };
        } // lib.mapAttrs' (group: agents: {
          name = "deployGroup-${group}";
          value = mkDeployAction {
            description = "Deploy the '${group}' group of this service.";
            inherit agents;
          };
        }) svc.nodes;
      }) cluster.config.services;
    };
  };
}
