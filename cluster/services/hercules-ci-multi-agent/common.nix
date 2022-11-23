{ config, inputs, lib, pkgs, ... }:

let
  mapAgents = lib.flip lib.mapAttrs config.services.hercules-ci-agents;

  #lib.foldl' (a: b: a // b) {} (lib.attrValues (lib.mapAttrs (basename: basevalue: lib.mapAttrs' (n: v: lib.nameValuePair "${n}-${basename}" v) basevalue) x));
  mergeMap = f: let
    outputs = mapAgents f;
  in  lib.pipe outputs [
    (lib.mapAttrs (basename: basevalue:
      lib.mapAttrs' (n: v:
        lib.nameValuePair "${n}-${basename}" v
      ) basevalue
    ))
    lib.attrValues
    (lib.foldl' (a: b: a // b) {})
  ];
in
{
  imports = [
    inputs.hercules-ci-agent.nixosModules.multi-agent-service
  ];

  age.secrets = mergeMap (name: _: {
    hci-token = {
      file = ./secrets + "/hci-token-${name}-${config.networking.hostName}.age";
      owner = "hci-${name}";
      group = "hci-${name}";
    };
    hci-cache-credentials = {
      file = ./secrets + "/hci-cache-credentials-${config.networking.hostName}.age";
      owner = "hci-${name}";
      group = "hci-${name}";
    };
    hci-cache-config = {
      file = ./secrets/hci-cache-config.age;
      owner = "hci-${name}";
      group = "hci-${name}";
    };
  });
  services.hercules-ci-agents.private-void = {
    settings = {
      clusterJoinTokenPath = config.age.secrets.hci-token-private-void.path;
      binaryCachesPath = config.age.secrets.hci-cache-config-private-void.path;
    };
  };
  systemd.services = mergeMap (name: _: {
    hercules-ci-agent = {
      # hercules-ci-agent-restarter should take care of this
      restartIfChanged = false;
      environment = {
        AWS_SHARED_CREDENTIALS_FILE = config.age.secrets."hci-cache-credentials-${name}".path;
      };
    };
  });
}
