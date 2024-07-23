{ testers, config, extendModules, lib, system }:

{ service }:

let
  serviceConfig = config.cluster.config.services.${service};
  serviceList = [ service ] ++ serviceConfig.simulacrum.deps;
  allAugments = map (svc: config.cluster.config.services.${svc}.simulacrum.augments) serviceList;

  lift = config;

  snakeoil = {
    ssh = {
      public = lib.fileContents ../../packages/checks/snakeoil/ssh/snakeoil-key.pub;
      private = ../../packages/checks/snakeoil/ssh/snakeoil-key;
    };
  };

  nodes = lib.attrNames config.gods.fromLight;
  digits = lib.attrsets.listToAttrs (lib.zipListsWith lib.nameValuePair nodes (lib.range 1 255));
  depot' = extendModules {
    modules = [
      ({ config, ... }: {
        gods.fromLight = lib.mapAttrs (name: cfg: {
          interfaces.primary = {
            link = lib.mkForce "vprimary";
          };
          ssh.id.publicKey = lib.mkForce snakeoil.ssh.public;
        }) lift.gods.fromLight;

        cluster = lib.mkForce (lift.cluster.extendModules {
          specialArgs.depot = config;
          modules = [
            { simulacrum = true; }
          ];
        });
      })
    ];
  };
  specialArgs = depot'.config.lib.summon system lib.id;
in

testers.runNixOSTest {
  name = "simulacrum-${service}";

  imports = [
    serviceConfig.simulacrum.settings
  ] ++ allAugments;

  _module.args = {
    inherit (depot'.config) cluster;
  };

  node = { inherit specialArgs; };
  nodes = lib.genAttrs nodes (node: let
    hour = depot'.config.hours.${node};
  in {
    imports = [
      specialArgs.depot.hours.${node}.nixos
      ../../packages/checks/modules/nixos/age-dummy-secrets
      ../../packages/checks/modules/nixos/external-storage.nix
    ] ++ depot'.config.cluster.config.out.injectNixosConfigForServices serviceList node;

    boot.kernel.sysctl."net.ipv4.ip_forward" = "1";
    networking = {
      interfaces = {
        ${hour.interfaces.primary.link} = {
          useDHCP = lib.mkForce false;
          virtual = true;
          ipv4.addresses = lib.mkForce [
            {
              address = hour.interfaces.primary.addr;
              prefixLength = 32;
            }
          ];
        };
        eth1.ipv4.routes = lib.pipe nodes [
          (lib.filter (n: n != node))
          (map (n: let
            hour = depot'.config.hours.${n};
          in {
            address = hour.interfaces.primary.addrPublic;
            prefixLength = 32;
            via = "192.168.1.${toString digits.${n}}";
          }))
        ];
      };

      firewall.extraCommands = lib.mkAfter (lib.optionalString (hour.interfaces.primary.isNat) ''
        # self-nat
        iptables -t nat -A PREROUTING -d ${hour.interfaces.primary.addrPublic} -j DNAT --to-destination ${hour.interfaces.primary.addr}
        iptables -t nat -A POSTROUTING -s ${hour.interfaces.primary.addr} -j SNAT --to-source ${hour.interfaces.primary.addrPublic}
      '');
    };

    systemd.services = {
      hyprspace.enable = false;
    };

    environment.etc = {
      "ssh/ssh_host_ed25519_key" = {
        source = snakeoil.ssh.private;
        mode = "0400";
      };
    };
    virtualisation = {
      cores = 2;
      memorySize = 4096;
    };
  });
}
