{ config, depot, lib, pkgs, ... }:

let
  cfg = config.services.garage;

  garageShellLibrary = pkgs.writeText "garage-shell-library.sh" ''
    getNodeId() {
      nodeId=""
      while [[ -z "$nodeId" ]]; do
        nodeId="$(garage status | grep 'NO ROLE ASSIGNED' | grep -wm1 "$1" | cut -d' ' -f1)"
        if [[ $? -ne 0 ]]; then
          echo "Waiting for node $1 to appear..." 2>/dev/null
          sleep 1
        fi
      done
      echo "$nodeId"
    }
    waitForGarage() {
      while ! garage status >/dev/null 2>/dev/null; do
        sleep 1
      done
    }
    waitForGarageOperational() {
      waitForGarage
      while garage layout show | grep -qwm1 '^Current cluster layout version: 0'; do
        sleep 1
      done
    }
  '';
in

{
  options.services.garage = with lib; {
    layout.initial = mkOption {
      default = {};
      type = with types; attrsOf (submodule {
        options = {
          zone = mkOption {
            type = types.str;
          };
          capacity = mkOption {
            type = types.ints.positive;
          };
        };
      });
    };
    keys = mkOption {
      type = with types; attrsOf (submodule {
        options = {
          allow = {
            createBucket = mkOption {
              description = "Allow the key to create new buckets.";
              type = bool;
              default = false;
            };
          };
          locksmith = {
            nodes = mkOption {
              description = "Nodes that this key will be made available to via Locksmith.";
              type = listOf str;
              default = [];
            };
            format = mkOption {
              description = "Locksmith secret format.";
              type = enum [ "files" "aws" "envFile" "s3ql" ];
              default = "files";
            };
            owner = mkOption {
              type = str;
              default = "root";
            };
            group = mkOption {
              type = str;
              default = "root";
            };
            mode = mkOption {
              type = str;
              default = "0400";
            };
          };
        };
      });
      default = {};
    };
    buckets = mkOption {
      type = with types; attrsOf (submodule {
        options = {
          allow = mkOption {
            description = "List of permissions to grant on this bucket, grouped by key name.";
            type = attrsOf (listOf (enum [ "read" "write" "owner" ]));
            default = {};
          };
          quotas = {
            maxObjects = mkOption {
              description = "Maximum number of objects in this bucket. Null for unlimited.";
              type = nullOr ints.positive;
              default = null;
            };
            maxSize = mkOption {
              description = "Maximum size of this bucket in bytes. Null for unlimited.";
              type = nullOr ints.positive;
              default = null;
            };
          };
          web.enable = mkEnableOption "website access for this bucket";
        };
      });
      default = {};
    };
  };

  config = {
    system.extraIncantations = {
      runGarage = i: script: i.execShellWith [ config.services.garage.package pkgs.gnugrep ] ''
        source ${garageShellLibrary}
        waitForGarage
        ${script}
      '';
    };

    systemd.services = {
      garage-layout-init = {
        distributed.enable = true;
        wantedBy = [ "garage.service" "multi-user.target" ];
        wants = [ "garage.service" ];
        after = [ "garage.service" ];
        path = [ config.services.garage.package ];

        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "1800s";
          Restart = "on-failure";
          RestartSec = "10s";
        };
        script = ''
          source ${garageShellLibrary}
          waitForGarage

          if [[ "$(garage layout show | grep -m1 '^Current cluster layout version:' | cut -d: -f2 | tr -d ' ')" != "0" ]]; then
            exit 0
          fi

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: layout: ''
            garage layout assign -z '${layout.zone}' -c '${toString layout.capacity}' "$(getNodeId '${name}')"
          '') cfg.layout.initial)}

          garage layout apply --version 1
        '';
      };
      garage-ready = {
        wants = [ "garage.service" ];
        after = [ "garage.service" "garage-layout-init.service" ];
        path = [ config.services.garage.package ];

        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "1800s";
          Restart = "on-failure";
          RestartSec = "10s";
        };
        script = ''
          source ${garageShellLibrary}
          waitForGarageOperational
        '';
      };
    };

    services.incandescence.providers.garage = {
      locksmith = true;
      wantedBy = [ "garage.service" "multi-user.target" ];
      partOf = [ "garage.service" ];
      wants = [ "garage-ready.service" ];
      after = [ "garage-ready.service" ];

      packages = [
        config.services.garage.package
      ];
      formulae = {
        key = {
          destroyAfterDays = 0;
          create = key: ''
            if [[ "$(garage key info ${lib.escapeShellArg key} 2>&1 >/dev/null)" == "Error: 0 matching keys" ]]; then
              # don't print secret key
              garage key new --name ${lib.escapeShellArg key} >/dev/null
              echo Key ${lib.escapeShellArg key} was created.
            else
              echo "Key already exists, assuming ownership"
            fi
          '';
          destroy = ''
            garage key delete --yes "$OBJECT"
          '';
          change = key: let
            kCfg = cfg.keys.${key};
          in ''
            garage key ${if kCfg.allow.createBucket then "allow" else "deny"} ${lib.escapeShellArg key} --create-bucket >/dev/null
          '';
        };
        bucket = {
          deps = [ "key" ];
          destroyAfterDays = 30;
          create = bucket: ''
            if [[ "$(garage bucket info ${lib.escapeShellArg bucket} 2>&1 >/dev/null)" == "Error: Bucket not found" ]]; then
              garage bucket create ${lib.escapeShellArg bucket}
            else
              echo "Bucket already exists, assuming ownership"
            fi
          '';
          destroy = ''
            garage bucket delete --yes "$OBJECT"
          '';
          change = bucket: let
            bCfg = cfg.buckets.${bucket};
          in ''
            # permissions
            ${lib.concatStringsSep "\n" (lib.flatten (
              lib.mapAttrsToList (key: perms: ''
                garage bucket allow ${lib.escapeShellArg bucket} --key ${lib.escapeShellArg key} ${lib.escapeShellArgs (map (x: "--${x}") perms)}
                garage bucket deny ${lib.escapeShellArg bucket} --key ${lib.escapeShellArg key} ${lib.escapeShellArgs (map (x: "--${x}") (lib.subtractLists perms [ "read" "write" "owner" ]))}
              '') bCfg.allow
            ))}

            # quotas
            garage bucket set-quotas ${lib.escapeShellArg bucket} \
              --max-objects '${if bCfg.quotas.maxObjects == null then "none" else toString bCfg.quotas.maxObjects}' \
              --max-size '${if bCfg.quotas.maxSize == null then "none" else toString bCfg.quotas.maxSize}'

            # website access
            garage bucket website ${if bCfg.web.enable then "--allow" else "--deny"} ${lib.escapeShellArg bucket}
          '';
        };
      };
    };

    services.locksmith.providers.garage = {
      secrets = lib.mkMerge (lib.mapAttrsToList (key: kCfg: let
        common = {
          inherit (kCfg.locksmith) mode owner group nodes;
        };
        getKeyID = "${cfg.package}/bin/garage key info ${lib.escapeShellArg key} | grep -m1 'Key ID:' | cut -d ' ' -f3";
        getSecretKey = "${cfg.package}/bin/garage key info ${lib.escapeShellArg key} | grep -m1 'Secret key:' | cut -d ' ' -f3";
      in if kCfg.locksmith.format == "files" then {
        "${key}-id" = common // {
          command = getKeyID;
        };
        "${key}-secret" = common // {
          command = getSecretKey;
        };
      } else let
        template = pkgs.writeText "garage-key-template" {
          aws = ''
            [default]
            aws_access_key_id=@@GARAGE_KEY_ID@@
            aws_secret_access_key=@@GARAGE_SECRET_KEY@@
          '';
          envFile = ''
            AWS_ACCESS_KEY_ID=@@GARAGE_KEY_ID@@
            AWS_SECRET_ACCESS_KEY=@@GARAGE_SECRET_KEY@@
          '';
          s3ql = ''
            [s3c]
            storage-url: s3c4://
            backend-login: @@GARAGE_KEY_ID@@
            backend-password: @@GARAGE_SECRET_KEY@@
          '';
        }.${kCfg.locksmith.format};
      in {
        ${key} = common // {
          command = pkgs.writeShellScript "garage-render-key-template" ''
            tmpFile="$(mktemp -ut garageKeyTemplate-XXXXXXXXXXXXXXXX)"
            cp ${template} "$tmpFile"
            trap "rm -f $tmpFile" EXIT
            chmod 600 "$tmpFile"
            ${getKeyID} | ${pkgs.replace-secret}/bin/replace-secret '@@GARAGE_KEY_ID@@' /dev/stdin "$tmpFile"
            ${getSecretKey} | ${pkgs.replace-secret}/bin/replace-secret '@@GARAGE_SECRET_KEY@@' /dev/stdin "$tmpFile"
            cat "$tmpFile"
          '';
        };
      }) cfg.keys);
    };
  };
}
