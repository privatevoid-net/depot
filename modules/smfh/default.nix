{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkOption
    types
  ;

  cfg = config.environment.smfh;

  manifest = pkgs.runCommand "smfh-manifest.json" {
    passAsFile = [ "smfhConfig" ];
    smfhConfig = builtins.toJSON {
      files = lib.mapAttrsToList (_: v: v) cfg.files;
      clobber_by_default = true;
      version = 3;
    };
  } ''
    ${pkgs.smfh}/bin/smfh --impure verify $smfhConfigPath
    cp $smfhConfigPath $out
  '';
in

{
  options.environment.smfh = {
    files = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          type = mkOption {
            type = types.enum [
              "copy"
              "symlink"
              "directory"
              "modify"
              "delete"
            ];
            default = "symlink";
          };

          target = mkOption {
            type = types.str;
            default = name;
          };

          source = mkOption {
            type = types.nullOr (types.coercedTo types.package (package: "${package}") types.str);
            default = null;
          };
        };
      }));
    };
  };

  config.systemd.user.services.smfh = {
    description = "SMFH";
    wantedBy = [ "graphical-session.target" ];
    before = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.smfh}/bin/smfh --impure activate ${manifest}";
  };
}
