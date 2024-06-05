{ testers, nixosModules, lib, s3ql, previous, system }:

testers.runNixOSTest {
  name = "s3ql-upgrade";

  nodes.machine = {
    imports = [
      nixosModules.ascensions
      nixosModules.external-storage
      nixosModules.systemd-extras
      ./modules/nixos/age-dummy-secrets.nix
    ];

    _module.args.depot.packages = { inherit (previous.packages.${system}) s3ql; };

    services.external-storage = {
      fileSystems.test = {
        mountpoint = "/srv/test";
        backend = "local:///mnt/backend";
      };
    };

    environment.etc."dummy-secrets/storageAuth-test".text = ''
      [local]
      storage-url: local://
    '';

    systemd.tmpfiles.settings.s3ql-storage."/mnt/backend".d.mode = "0700";

    system.ascensions.s3ql-test = {
      requiredBy = [ "remote-storage-test.service" ];
      before = [ "remote-storage-test.service" ];
      incantations = i: [];
    };

    specialisation.upgrade = {
      inheritParentConfig = true;
      configuration = {
        _module.args.depot = lib.mkForce { packages = { inherit s3ql; }; };
        system.ascensions.s3ql-test = {
          incantations = lib.mkForce (i: [
            (i.runS3qlUpgrade "test")
          ]);
        };
      };
    };
  };

  testScript = /*python*/ ''
    machine.wait_for_unit("remote-storage-test.service")
    machine.succeed("mkdir /srv/test/hello")
    machine.succeed("echo HelloWorld > /srv/test/hello/world.txt")

    with subtest("should upgrade"):
      machine.succeed("systemctl stop remote-storage-test.service")
      machine.succeed("/run/current-system/specialisation/upgrade/bin/switch-to-configuration test")
      machine.wait_for_unit("remote-storage-test.service")
      machine.succeed("systemctl is-active remote-storage-test.service")
      machine.succeed("test \"$(cat /srv/test/hello/world.txt)\" == HelloWorld")

    with subtest("should survive a restart"):
      machine.succeed("systemctl restart remote-storage-test.service")
      machine.wait_for_unit("remote-storage-test.service")
      machine.succeed("systemctl is-active remote-storage-test.service")
      machine.succeed("test \"$(cat /srv/test/hello/world.txt)\" == HelloWorld")
  '';
}
