{ lib, ... }:

{
  defaults.options.services.locksmith = lib.mkSinkUndeclaredOptions { };

  testScript = ''
    import json

    start_all()

    with subtest("should form cluster"):
      nodes = [ n for n in machines if n != nowhere ]
      for machine in nodes:
        machine.succeed("systemctl start consul-ready.service")
      for machine in nodes:
        consulConfig = json.loads(machine.succeed("cat /etc/consul.json"))
        addr = consulConfig["addresses"]["http"]
        port = consulConfig["ports"]["http"]
        setEnv = f"CONSUL_HTTP_ADDR={addr}:{port}"
        memberList = machine.succeed(f"{setEnv} consul members --status=alive")
        for machine2 in nodes:
          assert machine2.name in memberList
  '';
}
