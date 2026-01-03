{ cluster, lib, ... }:

let
  clusterName = "poseidon";
  link = cluster.config.links.patroni-pg-access;
  expectedReplicas = (lib.length cluster.config.services.patroni.nodes.worker) - 1;
in
{
  defaults = { depot, depot', pkgs, ... }: {
    environment.systemPackages = [
      pkgs.jq
      depot'.packages.postgresql
    ];
    services.patroni.settings.postgresql.pg_hba = [
      "host postgres postgres 0.0.0.0/0 trust"
    ];
  };

  # taken from https://github.com/phfroidmont/nixpkgs/blob/patroni-module/nixos/tests/patroni.nix
  testScript = ''
    import json
    nodeNames = json.loads('${builtins.toJSON cluster.config.services.patroni.nodes.worker}')
    clientNames = json.loads('${builtins.toJSON cluster.config.services.patroni.nodes.haproxy}')
    nodes = [ n for n in machines if n.name in nodeNames ]
    clients = [ n for n in machines if n.name in clientNames ]

    def booted(nodes):
      return filter(lambda node: node.booted, nodes)

    def wait_for_all_nodes_ready(expected_replicas=${toString expectedReplicas}):
        booted_nodes = booted(nodes)
        for node in booted_nodes:
            node.wait_for_unit("patroni.service")
            print(node.succeed("patronictl list ${clusterName}"))
            node.wait_until_succeeds(f"[ $(patronictl list -f json ${clusterName} | jq 'length') == {expected_replicas + 1} ]")
            node.wait_until_succeeds("[ $(patronictl list -f json ${clusterName} | jq 'map(select(.Role | test(\"^Leader$\"))) | map(select(.State | test(\"^running$\"))) | length') == 1 ]")
            node.wait_until_succeeds(f"[ $(patronictl list -f json ${clusterName} | jq 'map(select(.Role | test(\"^Replica$\"))) | map(select(.State | test(\"^streaming$\"))) | length') == {expected_replicas} ]")
            print(node.succeed("patronictl list ${clusterName}"))
        for client in booted(clients):
            client.wait_until_succeeds("psql -h ${link.ipv4} -p ${link.portStr} -U postgres --command='select 1;'")

    def run_dummy_queries():
        for client in booted(clients):
            client.succeed("psql -h ${link.ipv4} -p ${link.portStr} -U postgres --pset='pager=off' --tuples-only --command='insert into dummy(val) values (101);'")
            client.succeed("test $(psql -h ${link.ipv4} -p ${link.portStr} -U postgres --pset='pager=off' --tuples-only --command='select val from dummy where val = 101;') -eq 101")
            client.succeed("psql -h ${link.ipv4} -p ${link.portStr} -U postgres --pset='pager=off' --tuples-only --command='delete from dummy where val = 101;'")

    start_all()

    with subtest("should bootstrap a new patroni cluster"):
        wait_for_all_nodes_ready()

    with subtest("should be able to insert and select"):
        booted_clients = list(booted(clients))
        booted_clients[0].succeed("psql -h ${link.ipv4} -p ${link.portStr} -U postgres --command='create table dummy as select * from generate_series(1, 100) as val;'")
        for client in booted_clients:
            client.succeed("test $(psql -h ${link.ipv4} -p ${link.portStr} -U postgres --pset='pager=off' --tuples-only --command='select count(distinct val) from dummy;') -eq 100")

    with subtest("should restart after all nodes are crashed"):
        for node in nodes:
            node.crash()
        for node in nodes:
            node.start()
        wait_for_all_nodes_ready()

    with subtest("should be able to run queries while any one node is crashed"):
        masterNodeName = nodes[0].succeed("patronictl list -f json ${clusterName} | jq '.[] | select(.Role | test(\"^Leader$\")) | .Member' -r").strip()
        masterNodeIndex = next((i for i, v in enumerate(nodes) if v.name == masterNodeName))

        # Move master node at the end of the list to avoid multiple failovers (makes the test faster and more consistent)
        nodes.append(nodes.pop(masterNodeIndex))

        for node in nodes:
            node.crash()
            wait_for_all_nodes_ready(${toString (expectedReplicas - 1)})

            # Execute some queries while a node is down.
            run_dummy_queries()

            # Restart crashed node.
            node.start()
            wait_for_all_nodes_ready()

            # Execute some queries with the node back up.
            run_dummy_queries()

    with subtest("should create databases and users via incandescence"):
        for client in clients:
            client.succeed(f"PGPASSFILE=/run/locksmith/patroni-testuser psql -h ${link.ipv4} -p ${link.portStr} -U testuser -d testdb --command='create table test_table_{client.name} as select * from generate_series(1, 10) as val;'")
            client.fail("PGPASSFILE=/run/locksmith/patroni-testuser psql -h ${link.ipv4} -p ${link.portStr} -U testuser -d postgres --command='select * from dummy;'")

    with subtest("should take over existing databases and users via incandescence"):
        for cmd in [
            "drop database existingdb;",
            "drop user existinguser;",
            "create database existingdb owner postgres;",
            "create user existinguser;"
        ]:
            clients[0].succeed(f"psql -h ${link.ipv4} -p ${link.portStr} -U postgres --command='{cmd}'")

        for client in clients:
            client.fail(f"PGPASSFILE=/run/locksmith/patroni-existinguser psql -h ${link.ipv4} -p ${link.portStr} -U existinguser -d existingdb --command='create table test_table_{client.name} as select * from generate_series(1, 10) as val;'")

        consulConfig = json.loads(clients[0].succeed("cat /etc/consul.json"))
        addr = consulConfig["addresses"]["http"]
        port = consulConfig["ports"]["http"]
        setEnv = f"CONSUL_HTTP_ADDR={addr}:{port}"
        clients[0].succeed(f"{setEnv} consul kv delete --recurse services/incandescence/providers/patroni/formulae/database/existingdb")
        clients[0].succeed(f"{setEnv} consul kv delete --recurse services/incandescence/providers/patroni/formulae/user/existinguser")

        for client in clients:
            node.systemctl("start locksmith.service")
        for node in nodes:
            node.systemctl("restart incandescence-patroni.target")
            node.succeed("[[ \"$(systemctl is-active locksmith.service)\" != activating ]] || systemctl start locksmith.service")
        clients[0].succeed("[[ $(psql -h ${link.ipv4} -p ${link.portStr} -U postgres --tuples-only --csv --command=\"SELECT pg_roles.rolname FROM pg_database JOIN pg_roles ON pg_database.datdba = pg_roles.oid WHERE pg_database.datname = 'existingdb'\") == existinguser ]]")
        for client in clients:
            client.succeed(f"PGPASSFILE=/run/locksmith/patroni-existinguser psql -h ${link.ipv4} -p ${link.portStr} -U existinguser -d existingdb --command='create table test_table_{client.name} as select * from generate_series(1, 10) as val;'")
            client.fail("PGPASSFILE=/run/locksmith/patroni-existinguser psql -h ${link.ipv4} -p ${link.portStr} -U existinguser -d postgres --command='select * from dummy;'")
  '';
}
