{ config, lib, ... }:

{
  imports = [
    ./time-travel.nix
    ./hours.nix
    ./meta.nix
    ./nginx.nix
    ./identity.nix
  ];

  options.lib = lib.mkOption {
    default = {};
    type = with lib.types; submodule ({ extendModules, ... }: {
      freeformType = let
        t = either (lazyAttrsOf t) raw;
      in t;
      config.override = conf: let
        overridden = extendModules {
          modules = [ conf ];
        };
      in overridden.config;
    });
  };

  config = {
    _module.args.depot = config;
    flake = { inherit (config) lib; };
  };
}
