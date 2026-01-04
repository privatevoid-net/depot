{ cluster, lib, ... }:

let
  inherit (cluster.config.services.planetarium) nodes;
  firstNode = lib.elemAt nodes.mount 0;
  testDir = "/srv/planetarium/private/test";
in

{
  defaults.options.services.locksmith = lib.mkSinkUndeclaredOptions { };
  nodes = {
    ${firstNode} = {
      imports = [ ./snakeoil-secrets.nix ];
      users = {
        users = {
          testuser1 = {
            uid = 1501;
            isSystemUser = true;
            group = "testgroup";
          };
          testuser2 = {
            uid = 1502;
            isSystemUser = true;
            group = "testgroup";
          };
        };
        groups.testgroup.gid = 1500;
      };
      storage.planetarium.fileSystems.test = {
        uid = 1501;
        gid = 1500;
        storagePath = "file:///var/cache/zerofs-test/backend";
        keyFile = builtins.toFile "simulacrum-planetarium-key" ''
          ZEROFS_KEY=simulacrum
        '';
      };
      systemd.tmpfiles.settings.simulacrum = {
        "/var/cache/zerofs-test/backend".d.mode = "0777";
        "${testDir}/via-tmpfiles.txt".f.argument = "hello from systemd-tmpfiles";
      };
    };
  };
  testScript = ''
    machine = ${firstNode}
    machine.start()
    machine.wait_for_unit("multi-user.target")
    with subtest("should work with systemd-tmpfiles"):
      output = machine.succeed("runuser --user testuser1 -- cat ${testDir}/via-tmpfiles.txt")
      assert "hello from systemd-tmpfiles" in output

    with subtest("should enforce permissions"):
      machine.succeed("echo test | runuser --user testuser1 -- tee -a ${testDir}/test.txt")

      machine.fail("runuser --user testuser2 -- chmod 750 ${testDir}")
      machine.fail("runuser --user testuser2 -- chmod 640 ${testDir}/test.txt")
      machine.fail("runuser --user testuser2 -- cat ${testDir}/test.txt")

      output = machine.succeed("runuser --user testuser1 -- cat ${testDir}/test.txt")
      assert "test" in output

    with subtest("should be resilient against restarts"):
      machine.systemctl("restart zerofs-test.service")
      output = machine.succeed("runuser --user testuser1 -- cat ${testDir}/test.txt")
      assert "test" in output

      machine.systemctl("stop zerofs-test.service")
      output = machine.succeed("runuser --user testuser1 -- cat ${testDir}/test.txt")
      assert "test" in output

    with subtest("should reset permissions before mounting"):
      machine.execute("chown testuser2 ${testDir}")
      machine.succeed("runuser --user testuser2 -- touch ${testDir}/1")

      machine.systemctl("stop ${testDir}")
      machine.fail("runuser --user testuser2 -- touch ${testDir}/2")
  '';
}
