{ config, lib, ... }:

let
  cfg = config.services.garage;

  garageShellLibrary = /*bash*/ ''
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
  '';
in

{
  options.services.garage.layout = {
    initial = lib.mkOption {
      default = {};
      type = with lib.types; attrsOf (submodule {
        options = {
          zone = lib.mkOption {
            type = lib.types.str;
          };
          capacity = lib.mkOption {
            type = lib.types.ints.positive;
          };
        };
      });
    };
  };

  config = {
    system.extraIncantations = {
      runGarage = i: script: i.execShellWith [ config.services.garage.package ] ''
        ${garageShellLibrary}
        waitForGarage
        ${script}
      '';
    };

    systemd.services.garage-layout-init = {
      distributed.enable = true;
      wantedBy = [ "garage.service" ];
      after = [ "garage.service" ];
      path = [ config.services.garage.package ];

      serviceConfig = {
        TimeoutStartSec = "1800s";
      };
      script = ''
        ${garageShellLibrary}
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
  };
}
