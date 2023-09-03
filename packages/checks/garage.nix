{ testers, nixosModules, cluster, garage }:

testers.runNixOSTest {
  name = "garage";

  imports = [
    ./modules/consul.nix
  ];

  nodes = let
    common = { config, lib, ... }: let
      inherit (config.networking) hostName primaryIPAddress;
    in {
      imports = lib.flatten [
        ./modules/nixos/age-dummy-secrets.nix
        nixosModules.ascensions
        nixosModules.systemd-extras
        nixosModules.consul-distributed-services
        cluster.config.services.storage.nixos.garage
        cluster.config.services.storage.nixos.garageInternal
      ];
      config = {
        _module.args = {
          depot.packages = { inherit garage; };
          cluster.config = {
            hostLinks.${hostName} = {
              garageRpc.tuple = "${primaryIPAddress}:3901";
              garageS3.tuple = "${primaryIPAddress}:8080";
            };
            vars.meshNet.cidr = "192.168.0.0/16";
          };
        };
        environment.etc."dummy-secrets/garageRpcSecret".text = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        networking.firewall.allowedTCPPorts = [ 3901 8080 ];
        services.garage = {
          settings.consul_discovery.consul_http_addr = lib.mkForce "http://consul:8500";
          layout.initial = lib.mkOverride 51 {
            garage1 = { zone = "dc1"; capacity = 1000; };
            garage2 = { zone = "dc1"; capacity = 1000; };
            garage3 = { zone = "dc1"; capacity = 1000; };
          };
        };
        system.ascensions.garage-layout.incantations = lib.mkOverride 51 (i: [ ]);
        specialisation.modifiedLayout = {
          inheritParentConfig = true;
          configuration = {
            services.garage = {
              layout.initial = lib.mkForce {
                garage1 = { zone = "dc1"; capacity = 2000; };
                garage2 = { zone = "dc1"; capacity = 1000; };
                garage3 = { zone = "dc1"; capacity = 1000; };
              };
            };
            system.ascensions.garage-layout.incantations = lib.mkForce (i: [
              (i.runGarage ''
                garage layout assign -z dc1 -c 2000 "$(garage node id 2>/dev/null | cut -d@ -f1)"
                garage layout apply --version 2
              '')
            ]);
          };
        };
      };
    };
  in {
    garage1.imports = [ common ];
    garage2.imports = [ common ];
    garage3.imports = [ common ];
  };

  testScript = { nodes, ... }: /*python*/ ''
    nodes = [garage1, garage2, garage3]

    start_all()

    with subtest("should bootstrap new cluster"):
      for node in nodes:
          node.wait_for_unit("garage.service")

      for node in nodes:
          node.wait_until_fails("garage status | grep 'NO ROLE ASSIGNED'")

    with subtest("should apply new layout with ascension"):
      for node in nodes:
          node.systemctl("stop garage.service")

      for node in nodes:
          node.succeed("/run/current-system/specialisation/modifiedLayout/bin/switch-to-configuration test")

      for node in nodes:
          node.wait_until_succeeds("garage layout show | grep -w 2000")
          assert "1" in node.succeed("garage layout show | grep -w 2000 | wc -l")
          assert "2" in node.succeed("garage layout show | grep -w 1000 | wc -l")

    with subtest("should apply new layout from scratch"):
      for node in nodes:
          node.systemctl("stop garage.service")
          node.succeed("rm -rf /var/lib/garage-metadata")

      for node in nodes:
          node.systemctl("start garage.service")

      for node in nodes:
          node.wait_for_unit("garage.service")

      for node in nodes:
          node.wait_until_fails("garage status | grep 'NO ROLE ASSIGNED'")

      for node in nodes:
          node.wait_until_succeeds("garage layout show | grep -w 2000")
          assert "1" in node.succeed("garage layout show | grep -w 2000 | wc -l")
          assert "2" in node.succeed("garage layout show | grep -w 1000 | wc -l")
  '';
}
