{ config, depot, lib, pkgs, ... }:

let
  mapAgents = lib.flip lib.mapAttrs config.services.hercules-ci-agents;

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
    ./modules/multi-agent-refactored
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
  systemd.services = mergeMap (name: _: {
    hercules-ci-agent = {
      # hercules-ci-agent-restarter should take care of this
      restartIfChanged = false;
      environment = {
        AWS_SHARED_CREDENTIALS_FILE = config.age.secrets."hci-cache-credentials-${name}".path;
      };
      serviceConfig.Slice = "builder.slice";
    };
  });
}
