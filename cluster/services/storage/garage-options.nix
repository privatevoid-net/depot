{ config, lib, pkgs, ... }:

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
    # FIXME: returns bogus empty string when one of the lists is empty
    diffAdded() {
      comm -13 <(printf '%s\n' $1 | sort) <(printf '%s\n' $2 | sort)
    }
    diffRemoved() {
      comm -23 <(printf '%s\n' $1 | sort) <(printf '%s\n' $2 | sort)
    }
    # FIXME: this does not handle list items with spaces
    listKeys() {
      garage key list | tail -n +2 | grep -ow '[^ ]*$' || true
    }
    ensureKeys() {
      old="$(listKeys)"
      if [[ -z "$1" ]]; then
        for key in $old; do
          garage key delete --yes "$key"
        done
      elif [[ -z "$old" ]]; then
        for key in $1; do
          # don't print secret key
          garage key new --name "$key" >/dev/null
          echo Key "$key" was created.
        done
      else
        diffAdded "$old" "$1" | while read key; do
          # don't print secret key
          garage key new --name "$key" >/dev/null
          echo Key "$key" was created.
        done
        diffRemoved "$old" "$1" | while read key; do
          garage key delete --yes "$key"
        done
      fi
    }
    listBuckets() {
      garage bucket list | tail -n +2 | grep -ow '^ *[^ ]*' | tr -d ' ' || true
    }
    ensureBuckets() {
      old="$(listBuckets)"
      if [[ -z "$1" ]]; then
        for bucket in $old; do
          garage bucket delete --yes "$bucket"
        done
      elif [[ -z "$old" ]]; then
        for bucket in $1; do
          garage bucket create "$bucket"
        done
      else
        diffAdded "$old" "$1" | while read bucket; do
          garage bucket create "$bucket"
        done
        diffRemoved "$old" "$1" | while read bucket; do
          garage bucket delete --yes "$bucket"
        done
      fi
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
        options.allow = {
          createBucket = mkOption {
            description = "Allow the key to create new buckets.";
            type = bool;
            default = false;
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
      garage-apply = {
        distributed.enable = true;
        wantedBy = [ "garage.service" "multi-user.target" ];
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

          ensureKeys '${lib.concatStringsSep " " (lib.attrNames cfg.keys)}'
          ensureBuckets '${lib.concatStringsSep " " (lib.attrNames cfg.buckets)}'

          # key permissions
          ${lib.pipe cfg.keys [
            (lib.mapAttrsToList (key: kCfg: ''
              garage key ${if kCfg.allow.createBucket then "allow" else "deny"} '${key}' --create-bucket >/dev/null
            ''))
            (lib.concatStringsSep "\n")
          ]}

          # bucket permissions
          ${lib.pipe cfg.buckets [
            (lib.mapAttrsToList (bucket: bCfg:
              lib.mapAttrsToList (key: perms: ''
                garage bucket allow '${bucket}' --key '${key}' ${lib.escapeShellArgs (map (x: "--${x}") perms)}
                garage bucket deny '${bucket}' --key '${key}' ${lib.escapeShellArgs (map (x: "--${x}") (lib.subtractLists perms [ "read" "write" "owner" ]))}
              '') bCfg.allow
            ))
            lib.flatten
            (lib.concatStringsSep "\n")
          ]}

          # bucket quotas
          ${lib.pipe cfg.buckets [
            (lib.mapAttrsToList (bucket: bCfg: ''
              garage bucket set-quotas '${bucket}' \
                --max-objects '${if bCfg.quotas.maxObjects == null then "none" else toString bCfg.quotas.maxObjects}' \
                --max-size '${if bCfg.quotas.maxSize == null then "none" else toString bCfg.quotas.maxSize}'
            ''))
            (lib.concatStringsSep "\n")
          ]}

          # bucket website access
          ${lib.pipe cfg.buckets [
            (lib.mapAttrsToList (bucket: bCfg: ''
              garage bucket website ${if bCfg.web.enable then "--allow" else "--deny"} '${bucket}'
            ''))
            (lib.concatStringsSep "\n")
          ]}
        '';
      };
    };
  };
}
