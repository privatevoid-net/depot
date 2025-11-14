{ testers, nixosModules, lib, ipfs-cluster, previous, stdenv }:

testers.runNixOSTest {
  name = "ipfs-cluster-upgrade";

  extraBaseModules = {
    imports = [
      nixosModules.ipfs
      nixosModules.ipfs-cluster
      nixosModules.systemd-extras
    ];

    services.ipfs = {
      enable = true;
      apiAddress = "/ip4/127.0.0.1/tcp/5001";
    };
    services.ipfs-cluster = {
      enable = true;
      openSwarmPort = true;
      consensus = "crdt";
      package = previous.packages.${stdenv.hostPlatform.system}.ipfs-cluster;
    };
    specialisation.upgrade = {
      inheritParentConfig = true;
      configuration = {
        services.ipfs-cluster.package = lib.mkForce ipfs-cluster;
      };
    };
  };

  nodes.machine = {};

  testScript = /*python*/ ''
    machine.wait_for_unit("ipfs.service")
    machine.wait_for_unit("ipfs-cluster.service")
    machine.succeed("ipfs-cluster-ctl add -r -n TestPin123 /var/empty")
    
    machine.wait_for_unit("default.target")
    machine.succeed("systemctl stop ipfs-cluster.service")
    machine.succeed("/run/current-system/specialisation/upgrade/bin/switch-to-configuration test")

    machine.wait_for_unit("ipfs-cluster.service")
    machine.succeed("systemctl is-active ipfs-cluster.service")
    machine.succeed("ipfs-cluster-ctl pin ls | grep TestPin123")
  '';
}
