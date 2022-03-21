{ inputs, pkgs, ... }:
let
  inherit (pkgs) system;
  
  inherit (inputs.devshell.legacyPackages.${system}) mkShell;
  
  injectAttrName = name: value: value // { inherit name; };
  
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
