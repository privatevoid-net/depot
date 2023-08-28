{ nixosTest, nixosModules }:

let
  dataDir = {
    node1 = "/data/before";
    node2 = "/data/nested/after";
  };
  kvPath = {
    node1 = "before";
    node2 = "after";
  };
  addr = {
    consul = "10.0.0.10";
    node1 = "10.0.0.1";
    node2 = "10.0.0.2";
  };
in

nixosTest {
  name = "ascensions";
  nodes = let
    network = { config, lib, ... }: {
      networking.interfaces.eth1.ipv4.addresses = lib.mkForce [
        {
          address = addr.${config.networking.hostName};
          prefixLength = 24;
        }
      ];
    };
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
          environment.CONSUL_HTTP_ADDR = "${addr.consul}:8500";
        };
        ascend-create-kv = {
          environment.CONSUL_HTTP_ADDR = "${addr.consul}:8500";
        };
      };
      system.ascensions = {
        create-file = {
          before = [ "create-file.service" ];
          incantations = m: with m; lib.optionals (hostName == "node2") [
            (move dataDir.node1 dataDir.node2)
          ];
        };
        create-kv = {
          distributed = true;
          before = [ "create-kv.service" ];
          incantations = m: with m; lib.optionals (hostName == "node2") [
            (execShellWith [ config.services.consul.package ] ''
              consul kv put ${kvPath.node2} $(consul kv get ${kvPath.node1})
              consul kv delete ${kvPath.node1}
            '')
          ];
        };
      };
    };
  in {
    consul = {
      imports = [ network ];
      networking.firewall.allowedTCPPorts = [ 8500 ];
      services.consul = {
        enable = true;
        extraConfig = {
          addresses.http = addr.consul;
          bind_addr = addr.consul;
          server = true;
          bootstrap_expect = 1;
        };
      };
    };
    node1.imports = [ network common ];
    node2.imports = [ network common ];
  };
  testScript = /*python*/ ''
    start_all()
    consul.wait_for_unit("consul.service")
    consul.wait_until_succeeds("CONSUL_HTTP_ADDR=${addr.consul}:8500 consul members")
    node1.wait_for_unit("multi-user.target")
    node1.succeed("systemctl start create-file create-kv")
    node1.succeed("tar cvf /tmp/shared/data.tar /data /var/lib/ascensions")

    node2.wait_for_unit("multi-user.target")
    node2.succeed("tar xvf /tmp/shared/data.tar -C /")
    node2.succeed("systemctl start create-file create-kv")

    assert "node1" in node2.succeed("cat ${dataDir.node2}/file.txt")
    assert "node1" in consul.succeed("CONSUL_HTTP_ADDR=${addr.consul}:8500 consul kv get ${kvPath.node2}")
  '';
}
