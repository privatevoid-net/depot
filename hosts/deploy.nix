{ config, inputs, lib, self, withSystem, ... }:

let
  inherit (lib) elem mapAttrs toLower;
  inherit (config) gods cluster defaultEffectSystem;
  inherit (config.herculesCI) branch;
  inherit (self) nixosConfigurations;

  chosenHours = gods.fromLight;

  withEffectSystem = withSystem defaultEffectSystem;

  callUpon = name: host: withEffectSystem ({ hci-effects, ... }: let
    inherit (hci-effects) runIf runNixOS;
    inherit (host.enterprise) subdomain;

    hostname = "${toLower name}.${subdomain}.${cluster.domain}";

    deploy-rs = inputs.deploy-rs.lib."${host.system}";
  in {
    effect = runIf (elem branch [ "master" "staging" ]) (runNixOS {
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
  flake.effects = mapAttrs (pick "effect") calledUponHours;

  flake.deploy.nodes = mapAttrs (pick "deploy") calledUponHours;
}
