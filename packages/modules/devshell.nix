{ lib, config, inputs', ... }:
with lib;
let
  inherit (inputs'.devshell.legacyPackages) mkShell;

  wrapInAttrs = value: if builtins.isAttrs value then value else { inherit value; };

  wrapPackage = package: { inherit package; };

  injectAttrName = name: value: { inherit name; } // wrapInAttrs value;

  mkNamedAttrs = builtins.mapAttrs injectAttrName;

  attrsToNamedList = attrs: builtins.attrValues (mkNamedAttrs attrs);

  mkProjectShell = 
  {
    packages ? [],
    tools ? [],
    commands ? {},
    env ? {},
    config ? {}
  }:
  mkShell {
    imports = [
      config
      {
        commands = map wrapPackage tools;
      }
      {
        inherit packages;
        commands = attrsToNamedList commands;
        env = attrsToNamedList env;
      }
    ];
  };
in {
  options.projectShells = mkOption {
    default = {};
    type = types.attrsOf (types.submodule {
      options = {
        packages = mkOption {
          default = [];
          type = types.listOf types.package;
        };
        tools = mkOption {
          default = [];
          type = types.listOf types.package;
        };
        commands = mkOption {
          default = {};
          type = types.attrsOf types.package;
        };
        env = mkOption {
          default = {};
          type = with types; attrsOf (oneOf [ attrs str ] );
        };
        config = mkOption {
          default = {};
          type = types.anything;
        };
      };
    });
  };
  config.devShells = mapAttrs (_: mkProjectShell) config.projectShells;
}

