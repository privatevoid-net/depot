{
  testScript = ''
    import json

    start_all()

    with subtest("should form cluster"):
      for machine in machines:
        machine.succeed("systemctl start consul-ready.service")
      for machine in machines:
        consulConfig = json.loads(machine.succeed("cat /etc/consul.json"))
        addr = consulConfig["addresses"]["http"]
        port = consulConfig["ports"]["http"]
        setEnv = f"CONSUL_HTTP_ADDR={addr}:{port}"
        memberList = machine.succeed(f"{setEnv} consul members --status=alive")
        for machine2 in machines:
          assert machine2.name in memberList
  '';
}
