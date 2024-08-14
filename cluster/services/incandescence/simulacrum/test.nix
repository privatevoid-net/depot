{ cluster, lib, ... }:

let
  providers = lib.take 2 cluster.config.services.incandescence.nodes.provider;
in

{
  nodes = lib.genAttrs providers (lib.const {
    services.incandescence.providers.test = {
      wantedBy = [ "multi-user.target" ];
      partOf = [ ];
      formulae.example = {
        create = x: "consul kv put testData/${x} ${x}";
        destroy = "consul kv delete testData/$OBJECT";
      };
    };
  });

  testScript = ''
    import json
    nodeNames = json.loads('${builtins.toJSON providers}')
    nodes = [ n for n in machines if n.name in nodeNames ]

    start_all()

    consulConfig = json.loads(nodes[0].succeed("cat /etc/consul.json"))
    addr = consulConfig["addresses"]["http"]
    port = consulConfig["ports"]["http"]
    setEnv = f"CONSUL_HTTP_ADDR={addr}:{port}"

    with subtest("should create objects"):
      for node in nodes:
        node.wait_for_unit("incandescence-test.target")
      nodes[0].succeed(f"[[ $({setEnv} consul kv get testData/example1) == example1 ]]")
      nodes[0].succeed(f"[[ $({setEnv} consul kv get testData/example2) == example2 ]]")

    with subtest("should destroy objects"):
      nodes[0].succeed(f"{setEnv} consul kv put testData/example3 example3")
      nodes[0].succeed(f"{setEnv} consul kv put services/incandescence/providers/test/formulae/example/example3/alive true")
      nodes[1].succeed(f"{setEnv} consul kv get testData/example3")
      for node in nodes:
        node.systemctl("isolate default")
      for node in nodes:
        node.wait_for_unit("incandescence-test.target")
      nodes[0].fail(f"{setEnv} consul kv get testData/example3")
  '';
}
