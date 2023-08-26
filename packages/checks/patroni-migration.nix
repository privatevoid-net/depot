{ nixosTest, nixosModules, postgresql, previous, exampleData }:

nixosTest (
  let
    pgOld = previous.packages.postgresql;
    pgNew = postgresql;

    nodesIps = [
      "192.168.1.1"
      "192.168.1.2"
      "192.168.1.3"
    ];

    createNode = index: postgresql: { pkgs, ... }:
      let
        ip = builtins.elemAt nodesIps index; # since we already use IPs to identify servers
      in
      {
        imports = [
          nixosModules.patroni
          nixosModules.systemd-extras
        ];

        networking.interfaces.eth1.ipv4.addresses = pkgs.lib.mkOverride 0 [
          { address = ip; prefixLength = 16; }
        ];

        networking.firewall.allowedTCPPorts = [ 5432 8008 5010 ];

        environment.systemPackages = [ pkgs.jq ];

        systemd.tmpfiles.rules = [
          "d /data 0700 patroni patroni - -"
        ];
        services.patroni = {

          enable = true;

          migrations = {
            enable = true;
          };

          dataDir = "/data/patroni";
          postgresqlDataDir = "/data/postgres";

          postgresqlPackage = postgresql.withPackages (p: [ p.pg_safeupdate ]);

          scope = "cluster1";
          name = "node${toString(index + 1)}";
          nodeIp = ip;
          otherNodesIps = builtins.filter (h: h != ip) nodesIps;
          softwareWatchdog = true;

          settings = {
            bootstrap = {
              dcs = {
                ttl = 30;
                loop_wait = 10;
                retry_timeout = 10;
                maximum_lag_on_failover = 1048576;
              };
              initdb = [
                { encoding = "UTF8"; }
                "data-checksums"
              ];
            };

            postgresql = {
              use_pg_rewind = true;
              use_slots = true;
              authentication = {
                replication = {
                  username = "replicator";
                };
                superuser = {
                  username = "postgres";
                };
                rewind = {
                  username = "rewind";
                };
              };
              parameters = {
                listen_addresses = "${ip}";
                wal_level = "replica";
                hot_standby_feedback = "on";
                unix_socket_directories = "/tmp";
              };
              pg_hba = [
                "host replication replicator 192.168.1.0/24 md5"
                # Unsafe, do not use for anything other than tests
                "host all all 0.0.0.0/0 trust"
              ];
            };

            consul = {
              host = "192.168.1.4:8500";
              register_service = true;
            };
          };

          environmentFiles = {
            PATRONI_REPLICATION_PASSWORD = pkgs.writeText "replication-password" "postgres";
            PATRONI_SUPERUSER_PASSWORD = pkgs.writeText "superuser-password" "postgres";
            PATRONI_REWIND_PASSWORD = pkgs.writeText "rewind-password" "postgres";
          };
        };

        # We always want to restart so the tests never hang
        systemd.services.patroni.serviceConfig.StartLimitIntervalSec = 0;
      };
  in
  {
    name = "patroni";

    nodes = {
      node1 = createNode 0 pgOld;
      node2 = createNode 1 pgOld;
      node3 = createNode 2 pgOld;
      node1new = createNode 0 pgNew;
      node2new = createNode 1 pgNew;
      node3new = createNode 2 pgNew;

      consul = { pkgs, ... }: {

        networking.interfaces.eth1.ipv4.addresses = pkgs.lib.mkOverride 0 [
          { address = "192.168.1.4"; prefixLength = 16; }
        ];

        services.consul = {
          enable = true;
          extraConfig = {
            addresses.http = "192.168.1.4";
            server = true;
            bind_addr = "192.168.1.4";
            bootstrap_expect = 1;
          };
        };

        networking.firewall.allowedTCPPorts = [ 8500 ];
      };

      client = { pkgs, ... }: {
        environment.systemPackages = [ postgresql ];

        systemd.services.db-writer = {
          wantedBy = [ "multi-user.target" ];
          after = [ "haproxy.service" ];
          requires = [ "haproxy.service" ];
          serviceConfig.Type = "oneshot";
          script = ''
            set +e
            while ! ${pgNew}/bin/psql -h 127.0.0.1 -U postgres --command='create table dummy2 as select * from generate_series(1, 10) as val;'; do
              sleep 2;
            done
            i=11
            version="$(${pgNew}/bin/psql -h 127.0.0.1 -U postgres --pset='pager=off' --tuples-only --command='select version();')"
            while sleep .5; do
              newVersion=""
              while [[ -z "$newVersion" ]]; do
                newVersion="$(${pgNew}/bin/psql -h 127.0.0.1 -U postgres --pset='pager=off' --tuples-only --command='select version();')"
                sleep .5
              done
              echo $newVersion

              while ! ${pgNew}/bin/psql -h 127.0.0.1 -U postgres --pset='pager=off' --tuples-only --command="insert into dummy2 values($i);"; do
                retrying write for value $i
                sleep .5
              done
              echo wrote value $i
              i=$((i+1))

              if [[ "$newVersion" != "$version" ]]; then
                echo new version detected, quitting
                exit 0
              fi
            done
          '';
        };
        networking.interfaces.eth1.ipv4.addresses = pkgs.lib.mkOverride 0 [
          { address = "192.168.2.1"; prefixLength = 16; }
        ];

        services.haproxy = {
          enable = true;
          config = ''
            global
                maxconn 100

            defaults
                log global
                mode tcp
                retries 2
                timeout client 30m
                timeout connect 4s
                timeout server 30m
                timeout check 5s

            listen cluster1
                bind 127.0.0.1:5432
                option httpchk
                http-check expect status 200
                default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
                ${builtins.concatStringsSep "\n" (map (ip: "server postgresql_${ip}_5432 ${ip}:5432 maxconn 100 check port 8008") nodesIps)}
          '';
        };
      };
    };



    testScript = /*python*/ ''
      nodes = [node1, node2, node3]
      nodes_new = [node1new, node2new, node3new]
      node_pairs = [
          (1, node1, node1new),
          (2, node2, node2new),
          (3, node3, node3new)
      ]

      def wait_for_all_nodes_ready(nodes=nodes, expected_replicas=2):
          booted_nodes = filter(lambda node: node.booted, nodes)
          for node in booted_nodes:
              print(node.succeed("patronictl list cluster1"))
              node.wait_until_succeeds(f"[ $(patronictl list -f json cluster1 | jq 'length') == {expected_replicas + 1} ]")
              node.wait_until_succeeds("[ $(patronictl list -f json cluster1 | jq 'map(select(.Role | test(\"^Leader$\"))) | map(select(.State | test(\"^running$\"))) | length') == 1 ]")
              node.wait_until_succeeds(f"[ $(patronictl list -f json cluster1 | jq 'map(select(.Role | test(\"^Replica$\"))) | map(select(.State | test(\"^running$\"))) | length') == {expected_replicas} ]")
              print(node.succeed("patronictl list cluster1"))
          client.wait_until_succeeds("psql -h 127.0.0.1 -U postgres --command='select 1;'")

      def run_dummy_queries():
          client.succeed("psql -h 127.0.0.1 -U postgres --pset='pager=off' --tuples-only --command='insert into dummy(val) values (101);'")
          client.succeed("test $(psql -h 127.0.0.1 -U postgres --pset='pager=off' --tuples-only --command='select val from dummy where val = 101;') -eq 101")
          client.succeed("psql -h 127.0.0.1 -U postgres --pset='pager=off' --tuples-only --command='delete from dummy where val = 101;'")

      consul.start()
      client.start()
      for node in nodes:
        node.start()

      with subtest("should bootstrap a new patroni cluster"):
          wait_for_all_nodes_ready()

      with subtest("should be able to insert and select"):
          client.succeed("psql -h 127.0.0.1 -U postgres --command='create table dummy as select * from generate_series(1, 100) as val;'")
          client.succeed("test $(psql -h 127.0.0.1 -U postgres --pset='pager=off' --tuples-only --command='select count(distinct val) from dummy;') -eq 100")

      with subtest("should be able to load test database from dump"):
          client.succeed("psql -h 127.0.0.1 -U postgres --command='create database example;'")
          client.succeed("pg_restore -h 127.0.0.1 -U postgres -n public -d example ${exampleData}")

      with subtest("should upgrade to a new major version"):
          for (i, old, new) in node_pairs:
              old.succeed("systemctl stop patroni")
              old.succeed(f"tar cf /tmp/shared/data{i}.tar /data")
              old.shutdown()
              new.succeed(f"tar xf /tmp/shared/data{i}.tar -C /")

      with subtest("should be able to read and write after upgrade"):
          wait_for_all_nodes_ready(nodes=nodes_new)
          run_dummy_queries()

      #with subtest("should not have lost any data"):
      #    client.succeed("test $(psql -h 127.0.0.1 -U postgres --pset='pager=off' --tuples-only --command='select count(distinct val) from dummy2;') -eq $(psql -h 127.0.0.1 -U postgres --pset='pager=off' --tuples-only --command='select max(val) from dummy2;')")
    '';
  })
