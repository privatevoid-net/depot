{ config, inputs, lib, self, withSystem, ... }:

let
  inherit (lib) elem mapAttrs toLower;
  inherit (config) gods defaultEffectSystem;
  inherit (self) nixosConfigurations;

  meta = import ../tools/meta.nix;

  chosenHours = gods.fromLight;

  withEffectSystem = withSystem defaultEffectSystem;

  callUpon = name: host: withEffectSystem ({ config, hci-effects, ... }: let
    inherit (hci-effects) runIf runNixOS;
    inherit (host.enterprise) subdomain;

    hostname = "${toLower name}.${subdomain}.${meta.domain}";

    deploy-rs = inputs.deploy-rs.lib."${host.system}";
  in {
    effect = { branch, ... }: runIf (elem branch [ "master" "staging" ])
    (runNixOS rec {
      requiredSystemFeatures = [ "hci-deploy-agent-nixos" ];

      inherit (nixosConfigurations.${name}) config;

      secretsMap.ssh = "deploy-ssh";

      userSetupScript = ''
        writeSSHKey ssh
        cat >>~/.ssh/known_hosts <<EOF
        ${hostname} ${host.ssh.id.publicKey}
        EOF
      '';

      ssh.destination = "root@${hostname}";

      postEffect = let
        scheduleReboot = builtins.toFile "schedule-reboot.sh" /*bash*/ ''
          currentTime=$(date +%s)
          lastScheduledTime=$(consul kv get system/coordinated-reboot/last)
          if [[ $? -ne 0 ]]; then
            lastScheduledTime=$((currentTime - 300))
          fi
          nextScheduledTime=$((lastScheduledTime + 900))
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
      in hci-effects.ssh ssh /*bash*/ ''
        if [[ "$(realpath /run/booted-system/kernel)" != "$(realpath /run/current-system/kernel)" ]]; then
          echo "Scheduling reboot for kernel upgrade"
          if ! consul members >/dev/null; then
            echo "Consul not active, skipping reboot"
            exit 0
          fi
          consul lock --timeout=3m system/coordinated-reboot bash ${scheduleReboot}
        fi
      '';
    });

    deploy = {
      inherit hostname;
      profiles.system = {
        user = "root";
        sshUser = "deploy";
        path = deploy-rs.activate.nixos self.nixosConfigurations.${name};
      };
    };
  });

  calledUponHours = mapAttrs callUpon chosenHours;

  pick = format: _: calledUponHour: calledUponHour.${format};
in

{
  herculesCI = { config, ... }: let
    powers = mapAttrs (pick "effect") calledUponHours;
    wield = mapAttrs (_: wieldPowerWith: wieldPowerWith config.repo);
  in {
    onPush.default.outputs.effects = wield powers;
  };

  flake.deploy.nodes = mapAttrs (pick "deploy") calledUponHours;
}
