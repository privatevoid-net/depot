{ testers, nixosModules, cluster, garage, consul }:

testers.runNixOSTest {
  name = "garage";

  imports = [
    ./modules/consul.nix
  ];

  extraBaseModules.services.consul.package = consul;

  nodes = let
    common = { config, lib, ... }: let
      inherit (config.networking) hostName primaryIPAddress;
    in {
      imports = lib.flatten [
        ./modules/nixos/age-dummy-secrets
        ./modules/nixos/age-dummy-secrets/options.nix
        nixosModules.ascensions
        nixosModules.systemd-extras
        nixosModules.consul-distributed-services
        nixosModules.port-magic
        cluster.config.services.storage.nixos.garage
        cluster.config.services.storage.nixos.garageInternal
        cluster.config.services.consul.nixos.ready
      ];
      options.services.locksmith.providers = lib.mkOption {
        type = lib.types.raw;
      };
      config = {
        links.consulAgent = {
          protocol = "http";
          hostname = "consul";
          port = 8500;
        };
        _module.args = {
          depot.packages = { inherit garage; };
          cluster.config = {
            hostLinks.${hostName} = {
              garageRpc.tuple = "${primaryIPAddress}:3901";
              garageS3.tuple = "${primaryIPAddress}:8080";
              garageWeb.tuple = "${primaryIPAddress}:8081";
            };
            links.garageWeb.hostname = "web.garage.example.com";
            vars.meshNet.cidr = "192.168.0.0/16";
          };
        };
        environment.etc."dummy-secrets/garageRpcSecret".text = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        networking.firewall.allowedTCPPorts = [ 3901 8080 ];
        services.garage = {
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
              keys.testKey.allow.createBucket = true;
              buckets = {
                bucket1 = {
                  allow.testKey = [ "read" "write" ];
                  quotas = {
                    maxObjects = 300;
                    maxSize = 400 * 1024 * 1024;
                  };
                };
                bucket2 = {
                  allow.testKey = [ "read" ];
                };
              };
            };
            system.ascensions.garage-layout.incantations = lib.mkForce (i: [
              (i.runGarage ''
                garage layout assign -z dc1 -c 2000 "$(garage node id -q | cut -d@ -f1)"
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
        node.wait_until_succeeds('test "$(systemctl list-jobs | wc -l)" -eq 1')

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

    with subtest("should create specified buckets and keys"):
      for node in nodes:
        node.wait_until_succeeds('test "$(systemctl is-active garage-apply)" != activating')
      garage1.succeed("garage key list | grep testKey")
      garage1.succeed("garage bucket list | grep bucket1")
      garage1.succeed("garage bucket list | grep bucket2")

    with subtest("should delete unspecified buckets and keys"):
      garage1.succeed("garage bucket create unwantedbucket")
      garage1.succeed("garage key new --name unwantedkey")
      garage1.succeed("systemctl restart garage-apply.service")

      garage1.fail("garage key list | grep unwantedkey")
      garage1.fail("garage bucket list | grep unwantedbucket")
  '';
}
