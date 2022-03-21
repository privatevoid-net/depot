{ inputs, pkgs, ... }:
let
  inherit (pkgs) system;
  
  inherit (inputs.devshell.legacyPackages.${system}) mkShell;
  
  wrapInAttrs = value: if builtins.isAttrs value then value else { inherit value; };
  
  injectAttrName = name: value: { inherit name; } // wrapInAttrs value;
  
  mkNamedAttrs = builtins.mapAttrs injectAttrName;
  
  attrsToNamedList = attrs: builtins.attrValues (mkNamedAttrs attrs);
in
  {
    packages ? [],
    commands ? {},
    env ? {},
    config ? {}
  }:
  mkShell {
    imports = [
      config
      {
        inherit packages;
        commands = attrsToNamedList commands;
        env = attrsToNamedList env;
      }
    ];
  }
