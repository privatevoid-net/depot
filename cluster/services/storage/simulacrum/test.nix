{ cluster, lib, ... }:

let
  inherit (cluster.config.services.storage) nodes;

  firstGarageNode = lib.elemAt nodes.garage 0;

  getPreviousVersion = currentVersion: let
    currentMajor = lib.versions.major currentVersion;
    currentMinor = lib.versions.minor currentVersion;
    downgrade = num: toString ((lib.toInt num) - 1);
    previousVersion = if currentMajor == "0"
      then [ "0" (downgrade currentMinor) ]
      else if currentMajor == "1" then [ "0" "9" ]
      else [ (downgrade currentMajor) ];
    in {
      version = lib.concatStringsSep "." previousVersion;
      attr = lib.concatStringsSep "_" previousVersion;
    };

  useCurrentGarage = { depot', ... }: {
    services.garage.package = lib.mkForce depot'.packages.garage;
  };
in

{
  nodes = lib.genAttrs nodes.garage (node: { depot, depot', pkgs, ... }: {
    services.garage = {
      layout.initial = lib.genAttrs nodes.garage (_: {
        capacity = lib.mkOverride 51 1000;
        zone = lib.mkForce "eu-central";
      });
      package = let
        prev = getPreviousVersion depot'.packages.garage.version;
        attr = "garage_${prev.attr}";
        package = depot'.packages.${attr} or pkgs.${attr};
      in lib.mkOverride 51 (depot.lib.ignoreVulnerabilities package);
    };
    specialisation = {
      upgrade = {
        inheritParentConfig = true;
        configuration = useCurrentGarage;
      };
      modifiedLayout = {
        inheritParentConfig = true;
        configuration = {
          imports = [ useCurrentGarage ];
          services.garage = {
            layout.initial.${firstGarageNode}.capacity = lib.mkForce 2000;
          };
          system.ascensions.garage-layout.incantations = lib.mkForce (i: [
            (i.runGarage ''
              garage layout assign -z eu-central -c 2000GB "$(garage node id -q | cut -d@ -f1)"
              garage layout apply --version 2
            '')
          ]);
        };
      };
    };
  });

  testScript = ''
    import json
    nodes = [n for n in machines if n.name in json.loads('${builtins.toJSON nodes.garage}')]
    garage1 = nodes[0]

    start_all()

    with subtest("should bootstrap new cluster"):
      for node in nodes:
        node.wait_for_unit("garage.service")

      for node in nodes:
        node.wait_until_fails("garage status | grep 'NO ROLE ASSIGNED'")

      for node in nodes:
        node.wait_until_succeeds("garage layout show | grep -w 'Current cluster layout version: 1'")

    with subtest("should upgrade from previous version"):
      for node in nodes:
        node.wait_until_succeeds('test "$(systemctl list-jobs | wc -l)" -eq 1')

      from concurrent.futures import ThreadPoolExecutor

      with ThreadPoolExecutor(max_workers=len(nodes)) as ex:
        for node in nodes:
          ex.submit(node.succeed, "/run/booted-system/specialisation/upgrade/bin/switch-to-configuration test")
        ex.shutdown()

    with subtest("should apply new layout with ascension"):
      for node in nodes:
        node.wait_until_succeeds('test "$(systemctl list-jobs | wc -l)" -eq 1')

      for node in nodes:
        node.succeed("/run/booted-system/specialisation/modifiedLayout/bin/switch-to-configuration test")

      for node in nodes:
        node.wait_until_succeeds("garage layout show | grep -w 'eu-central  *2\\.0 TB'")
        assert "1" in node.succeed("garage layout show | grep -w 'eu-central  *2\\.0 TB' | wc -l")
        assert "2" in node.succeed("garage layout show | grep -w 'eu-central  *1000\\.0 GB' | wc -l")

    consulConfig = json.loads(garage1.succeed("cat /etc/consul.json"))
    addr = consulConfig["addresses"]["http"]
    port = consulConfig["ports"]["http"]
    setEnv = f"CONSUL_HTTP_ADDR={addr}:{port}"
    with subtest("should apply new layout from scratch"):
      for node in nodes:
        node.systemctl("stop garage.service")
        node.succeed("rm -rf /var/lib/garage-metadata")
      garage1.succeed(f"{setEnv} consul kv delete --recurse services/incandescence/providers/garage")

      for node in nodes:
        node.systemctl("start garage.service")

      for node in nodes:
        node.wait_for_unit("garage.service")

      for node in nodes:
        node.wait_until_fails("garage status | grep 'NO ROLE ASSIGNED'")

      for node in nodes:
        node.wait_until_succeeds("garage layout show | grep -w 'eu-central  *2\\.0 TB'")
        assert "1" in node.succeed("garage layout show | grep -w 'eu-central  *2\\.0 TB' | wc -l")
        assert "${toString ((lib.length nodes.garage) - 1)}" in node.succeed("garage layout show | grep -w 'eu-central  *1000\\.0 GB' | wc -l")

    with subtest("should create specified buckets and keys"):
      for node in nodes:
        node.wait_for_unit("incandescence-garage.target")
      garage1.succeed("garage key list | grep testkey")
      garage1.succeed("garage bucket list | grep testbucket")

    with subtest("should delete unspecified keys"):
      garage1.succeed("garage bucket create unwantedbucket")
      garage1.succeed("garage key create unwantedkey || garage key new --name unwantedkey")
      garage1.succeed(f"{setEnv} consul kv put services/incandescence/providers/garage/formulae/key/unwantedkey/alive true")
      garage1.succeed(f"{setEnv} consul kv put services/incandescence/providers/garage/formulae/bucket/unwantedbucket/alive true")
      garage1.succeed("systemctl restart garage.service")
      garage1.wait_for_unit("incandescence-garage.target")
      garage1.fail("garage key list | grep unwantedkey")
      garage1.succeed("garage bucket list | grep unwantedbucket")

    with subtest("should delete unspecified buckets after grace period"):
      garage1.succeed(f"{setEnv} consul kv put services/incandescence/providers/garage/formulae/bucket/unwantedbucket/destroyOn 1")
      garage1.succeed("systemctl restart garage.service")
      garage1.wait_for_unit("incandescence-garage.target")
      garage1.fail("garage bucket list | grep unwantedbucket")
  '';
}
