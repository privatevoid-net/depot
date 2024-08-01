{ cluster, config, depot, lib, ... }:

let
  inherit (cluster.config.services.hercules-ci-multi-agent) nodes secrets;

  mapAgents = lib.flip lib.mapAttrs nodes;

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

  systemd.services = mergeMap (_: _: {
    hercules-ci-agent = {
      # hercules-ci-agent-restarter should take care of this
      restartIfChanged = false;
      environment = {
        AWS_SHARED_CREDENTIALS_FILE = secrets.cacheCredentials.path;
        AWS_EC2_METADATA_DISABLED = "true";
      };
      serviceConfig.Slice = "builder.slice";
    };
  });

  services.hercules-ci-agents = lib.genAttrs (lib.attrNames nodes) (org: {
    enable = true;
    package = depot.inputs.hercules-ci-agent.packages.hercules-ci-agent;
    settings = {
      clusterJoinTokenPath = secrets."clusterJoinToken-${org}".path;
      binaryCachesPath = secrets.cacheConfig.path;
      concurrentTasks = lib.pipe config.reflection.hardware.cpu.cores [
        (lib.flip builtins.div 2)
        builtins.floor
        (lib.max 2)
      ];
    };
  });

  nix.settings.cores = lib.pipe config.reflection.hardware.cpu.cores [
    (builtins.mul 0.75)
    builtins.floor
    (lib.max 1)
  ];

  users.groups.hercules-ci-agent.members = map (org: "hci-${org}") (lib.attrNames nodes);
}
