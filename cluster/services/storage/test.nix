{ cluster, lib, ... }:

let
  inherit (cluster.config.services.storage) nodes;

  firstGarageNode = lib.elemAt nodes.garage 0;
in

{
  nodes = lib.genAttrs nodes.garage (node: {
    services.garage = {
      layout.initial = lib.genAttrs nodes.garage (_: {
        capacity = lib.mkOverride 51 1000;
      });
    };
    specialisation.modifiedLayout = {
      inheritParentConfig = true;
      configuration = {
        services.garage = {
          layout.initial.${firstGarageNode}.capacity = lib.mkForce 2000;
        };
        system.ascensions.garage-layout.incantations = lib.mkForce (i: [
          (i.runGarage ''
            garage layout assign -z eu-central -c 2000 "$(garage node id -q | cut -d@ -f1)"
            garage layout apply --version 2
          '')
        ]);
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

    with subtest("should apply new layout with ascension"):
      for node in nodes:
        node.wait_until_succeeds('test "$(systemctl list-jobs | wc -l)" -eq 1')

      for node in nodes:
        node.succeed("/run/current-system/specialisation/modifiedLayout/bin/switch-to-configuration test")

      for node in nodes:
        node.wait_until_succeeds("garage layout show | grep -w 2000")
        assert "1" in node.succeed("garage layout show | grep -w 2000 | wc -l")
        assert "2" in node.succeed("garage layout show | grep -w 1000 | wc -l")

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
        node.wait_until_succeeds("garage layout show | grep -w 2000")
        assert "1" in node.succeed("garage layout show | grep -w 2000 | wc -l")
        assert "${toString ((lib.length nodes.garage) - 1)}" in node.succeed("garage layout show | grep -w 1000 | wc -l")

    with subtest("should create specified buckets and keys"):
      for node in nodes:
        node.wait_for_unit("incandescence-garage.target")
      garage1.succeed("garage key list | grep testkey")
      garage1.succeed("garage bucket list | grep testbucket")

    with subtest("should delete unspecified keys"):
      garage1.succeed("garage bucket create unwantedbucket")
      garage1.succeed("garage key new --name unwantedkey")
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

