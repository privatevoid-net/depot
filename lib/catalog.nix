{ config, lib, withSystem, ... }:

{
  lib = {
    catalog = {
      init = lib.genAttrs config.systems (system: withSystem system ({ config, ... }: lib.mapAttrsToList (name: cell: {
        cell = name;
        cellBlocks = lib.mapAttrsToList (name: block: {
          blockType = "catalogBlock";
          cellBlock = name;
          targets = lib.mapAttrsToList (name: target: {
            inherit name;
            inherit (target) description;
            actions = lib.mapAttrsToList (name: action: {
              inherit name;
              inherit (action) description;
            }) target.actions;
          }) block;
        }) cell;
      }) config.catalog));

      actions = lib.genAttrs config.systems (system: withSystem system ({ config, pkgs, ... }:
        lib.mapAttrs (name: cell:
          lib.mapAttrs (name: block:
            lib.mapAttrs (name: target:
              lib.mapAttrs (name: action:
                let
                  binPath = lib.makeBinPath action.packages;
                in pkgs.writeShellScript name ''
                  # Void CLI Action
                  # ---
                  ${lib.optionalString (action.packages != []) ''export PATH="${binPath}:$PATH"''}
                  # ---
                  ${action.command}
                '') target.actions
            ) block
          ) cell
        )
      config.catalog));
    };
  };
}
