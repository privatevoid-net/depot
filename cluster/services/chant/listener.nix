{ config, lib, pkgs, ... }:

let
  consul = config.links.consulAgent;

  validTargets = lib.pipe config.systemd.services [
    (lib.filterAttrs (name: value: value.chant.enable))
    lib.attrNames
  ];

  validTargetsJson = pkgs.writeText "chant-targets.json" (builtins.toJSON validTargets);

  eventHandler = pkgs.writers.writePython3 "chant-listener-event-handler" {
    flakeIgnore = [ "E501" ];
  } ''
    import json
    import sys
    import os
    import subprocess
    import base64

    validTargets = set()
    with open("${validTargetsJson}", "r") as f:
        validTargets = set(json.load(f))

    events = json.load(sys.stdin)

    cacheDir = os.getenv("CACHE_DIRECTORY", "/var/cache/chant")

    indexFile = f"{cacheDir}/index"

    oldIndex = "old-index"
    if os.path.isfile(indexFile):
        with open(indexFile, "r") as f:
            oldIndex = f.readline()

    newIndex = os.getenv("CONSUL_INDEX", "no-index")

    if oldIndex != newIndex:
        triggers = set()
        for event in events:
            if event["Name"].startswith("chant:"):
                target = event["Name"].removeprefix("chant:")
                if target not in validTargets:
                    print(f"Skipping invalid target: {target}")
                    continue
                with open(f"/run/chant/{target}", "wb") as f:
                    if event["Payload"] is not None:
                        f.write(base64.b64decode(event["Payload"]))
                triggers.add(target)

        for trigger in triggers:
            subprocess.run(["${config.systemd.package}/bin/systemctl", "start", f"{trigger}.service"])

    with open(indexFile, "w") as f:
        f.write(newIndex)
  '';
in
{
  systemd.services.chant-listener = {
    description = "Chant Listener";
    wantedBy = [ "multi-user.target" ];
    requires = [ "consul-ready.service" ];
    after = [ "consul-ready.service" ];
    serviceConfig = {
      ExecStart = "${config.services.consul.package}/bin/consul watch --type=event ${eventHandler}";

      RuntimeDirectory = "chant";
      RuntimeDirectoryMode = "0700";
      CacheDirectory = "chant";
      CacheDirectoryMode = "0700";

      RestartSec = 60;
      Restart = "always";
      IPAddressDeny = [ "any" ];
      IPAddressAllow = [ consul.ipv4 ];
    };
    environment = {
      CONSUL_HTTP_ADDR = consul.tuple;
    };
  };
}
