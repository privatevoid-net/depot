{ config, lib, pkgs, ... }:

let
  cfg = config.nixpkgs;
  inherit (lib) mkOption types;
in

{
  disabledModules = [
    "misc/nixpkgs.nix"
    "misc/nixpkgs/read-only.nix"
  ];

  options = {
    nixpkgs = {
      instances = mkOption {
        type = types.attrsOf types.pkgs;
        readOnly = true;
      };
      system = mkOption {
        internal = true;
        readOnly = true;
        type = types.str;
        default = pkgs.stdenv.hostPlatform.system;
      };
      pkgs = mkOption {
        type = types.pkgs;
        description = ''The pkgs module argument.'';
      };
      config = mkOption {
        internal = true;
        readOnly = true;
        type = types.unique { message = "nixpkgs.config is set to read-only"; } types.anything;
        description = ''
          The Nixpkgs `config` that `pkgs` was initialized with.
        '';
        default = pkgs.config;
      };
      overlays = mkOption {
        internal = true;
        type = types.unique { message = "nixpkgs.overlays is set to read-only"; } types.anything;
        description = ''
          The Nixpkgs overlays that `pkgs` was initialized with.
        '';
      };
      hostPlatform = mkOption {
        type = lib.types.either lib.types.str lib.types.attrs;
        description = ''
          The platform of the machine that is running the NixOS configuration.
        '';
        apply = lib.systems.elaborate;
      };
      buildPlatform = mkOption {
        type = lib.types.either lib.types.str lib.types.attrs;
        description = ''
          The platform of the machine that built the NixOS configuration.
        '';
        default = cfg.hostPlatform;
        apply = lib.flip lib.pipe [
          lib.systems.elaborate
          (platform:
            if lib.systems.equals platform cfg.hostPlatform
              then cfg.hostPlatform
              else platform
          )
        ];
      };
    };
  };

  config = {
    nixpkgs.overlays = lib.mkForce [];
    _module.args.pkgs =
      assert cfg.buildPlatform == cfg.hostPlatform;
        cfg.instances.${cfg.hostPlatform.system};
  };
}
