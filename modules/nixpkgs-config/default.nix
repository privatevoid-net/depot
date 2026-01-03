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
        description = ''
          The platform of the machine that is running the NixOS configuration.
        '';
      };
      buildPlatform = mkOption {
        description = ''
          The platform of the machine that built the NixOS configuration.
        '';
        default = cfg.hostPlatform;
      };
    };
  };

  config = {
    nixpkgs.overlays = lib.mkForce [];
    _module.args.pkgs =
      assert cfg.buildPlatform == cfg.hostPlatform;
        cfg.instances.${cfg.hostPlatform};
  };
}
