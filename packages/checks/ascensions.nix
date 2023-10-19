{ testers, nixosModules }:

let
  dataDir = {
    node1 = "/data/before";
    node2 = "/data/nested/after";
  };
  kvPath = {
    node1 = "before";
    node2 = "after";
  };
in

testers.runNixOSTest {
  name = "ascensions";

  imports = [
    ./modules/consul.nix
  ];

  nodes = let
    common = { config, lib, ... }: let
      inherit (config.networking) hostName;
    in {
      imports = [
        nixosModules.ascensions
        nixosModules.systemd-extras
        nixosModules.consul-distributed-services
      ];
      systemd.services = {
        create-file = {
          serviceConfig.Type = "oneshot";
          script = ''
            if ! test -e ${dataDir.${hostName}}/file.txt; then
              mkdir -p ${dataDir.${hostName}}
              echo "${hostName}" > ${dataDir.${hostName}}/file.txt
            fi
          '';
        };
        create-kv = {
          serviceConfig.Type = "oneshot";
          path = [ config.services.consul.package ];
          script = ''
            if ! consul kv get ${kvPath.${hostName}}; then
              consul kv put ${kvPath.${hostName}} ${hostName}
            fi
          '';
          environment.CONSUL_HTTP_ADDR = "consul:8500";
        };
        ascend-create-kv = {
          environment.CONSUL_HTTP_ADDR = "consul:8500";
        };
      };
      system.ascensions = {
        create-file = {
          before = [ "create-file.service" ];
          incantations = m: with m; lib.optionals (hostName == "node2") [
            (move dataDir.node1 "/data/somewhere/intermediate1")
            (move "/data/somewhere/intermediate1" "/var/lib/intermediate2")
            (move "/var/lib/intermediate2" dataDir.node2)
          ];
        };
        create-kv = {
          distributed = true;
          before = [ "create-kv.service" ];
          incantations = m: with m; lib.optionals (hostName == "node2") [
            (execShellWith [ config.services.consul.package ] ''
              consul kv put intermediate/data $(consul kv get ${kvPath.node1})
              consul kv delete ${kvPath.node1}
            '')
            (execShellWith [ config.services.consul.package ] ''
              consul kv put ${kvPath.node2} $(consul kv get intermediate/data)
              consul kv delete intermediate/data
            '')
          ];
        };
      };
    };
  in {
    node1.imports = [ common ];
    node2.imports = [ common ];
  };
  testScript = /*python*/ ''
    node1.start()
    consul.wait_for_unit("consul.service")
    consul.wait_until_succeeds("CONSUL_HTTP_ADDR=consul:8500 consul members")
    node1.wait_for_unit("multi-user.target")
    node1.succeed("systemctl start create-file create-kv")
    node1.succeed("tar cvf /tmp/shared/data.tar /data /var/lib/ascensions")

    node2.wait_for_unit("multi-user.target")
    node2.succeed("rm -rf /data")
    node2.succeed("tar xvf /tmp/shared/data.tar -C /")
    node2.succeed("systemctl start create-file create-kv")

    assert "node1" in node2.succeed("cat ${dataDir.node2}/file.txt")
    assert "node1" in consul.succeed("CONSUL_HTTP_ADDR=consul:8500 consul kv get ${kvPath.node2}")
  '';
}
