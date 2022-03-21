{ inputs, pkgs, ... }:
let
  inherit (pkgs) system;
  
  inherit (inputs.devshell.legacyPackages.${system}) mkShell;
  
  wrapInAttrs = value: if builtins.isAttrs value then value else { inherit value; };
  
  wrapPackage = package: { inherit package; };

  injectAttrName = name: value: { inherit name; } // wrapInAttrs value;
  
  mkNamedAttrs = builtins.mapAttrs injectAttrName;
  
  attrsToNamedList = attrs: builtins.attrValues (mkNamedAttrs attrs);
in
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
  }
