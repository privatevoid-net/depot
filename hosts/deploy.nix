{ config,  lib, self, withSystem, ... }:

let
  inherit (lib) const elem flip genAttrs mapAttrs';
  inherit (config) gods defaultEffectSystem systems;
  inherit (self) nixosConfigurations;

  chosenHours = gods.fromLight;

  withEffectSystem = withSystem defaultEffectSystem;

  callUpon = hour: { ${hour} = nixosConfigurations.${hour}.config.system.build.toplevel; };
in

{
  herculesCI = { config, ... }: {
    onPush.default.outputs.effects = mapAttrs' (hour: const {
      name = "deploy-${hour}";
      value = withEffectSystem ({  hci-effects, ... }: let
        inherit (hci-effects) runIf runCachixDeploy;
      in runIf (elem config.repo.branch [ "master" "staging" ]) (
        runCachixDeploy {
          async = true;
          deploy = {
            agents = callUpon hour;
            rollbackScript = genAttrs systems (flip withSystem ({ pkgs, ... }:
              let
                scheduleReboot = pkgs.writeShellScript "schedule-reboot.sh" ''
                  export PATH="${pkgs.consul}/bin:${pkgs.systemd}/bin:${pkgs.coreutils}/bin"
                  currentTime=$(date +%s)
                  lastScheduledTime=$(consul kv get system/coordinated-reboot/last)
                  if [[ $? -ne 0 ]]; then
                    lastScheduledTime=$((currentTime - 300))
                  fi
                  nextScheduledTime=$((lastScheduledTime + 3600))
                  if [[ $nextScheduledTime -lt $((currentTime + 300)) ]]; then
                    nextScheduledTime=$((currentTime + 300))
                  fi
                  consul kv put system/coordinated-reboot/last $nextScheduledTime
                  echo "Scheduling reboot for $nextScheduledTime"
                  systemd-analyze timestamp @$nextScheduledTime
                  busctl call \
                    org.freedesktop.login1 \
                    /org/freedesktop/login1 \
                    org.freedesktop.login1.Manager \
                    ScheduleShutdown st reboot ''${nextScheduledTime}000000
                '';
              in pkgs.writeShellScript "post-effect.sh" ''
                export PATH="${pkgs.consul}/bin:${pkgs.coreutils}/bin"
                if [[ "$(realpath /run/booted-system/kernel)" != "$(realpath /nix/var/nix/profiles/system/kernel)" ]]; then
                  echo "Scheduling reboot for kernel upgrade"
                  if ! consul members >/dev/null; then
                    echo "Consul not active, skipping reboot"
                    exit 0
                  fi
                  consul lock --timeout=3m system/coordinated-reboot ${scheduleReboot}
                fi
              ''
            ));
          };
        }
      ));
    }) chosenHours;
  };
}
