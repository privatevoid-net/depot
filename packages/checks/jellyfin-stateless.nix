{ nixosTest, cluster, jellyfin }:

nixosTest {
  name = "jellyfin-stateless";
  nodes = {
    machine = {
      imports = cluster.config.services.warehouse.nixos.host;

      _module.args.depot.packages.jellyfin = jellyfin;
    };
  };
  testScript = /*python*/ ''
    def start_jf():
        machine.succeed("systemctl start jellyfin.service")
        machine.wait_for_unit("jellyfin.service")
        machine.wait_for_open_port(8096)
        machine.wait_until_succeeds("curl --fail http://127.0.0.1:8096")

    def stop_jf():
        machine.succeed("systemctl stop jellyfin.service")

    machine.wait_for_unit("jellyfin.service")

    start_jf()
    machine.succeed("sed -i 's,EncoderAppPathDisplay,EncoderAppPath,g' /var/lib/jellyfin/config/encoding.xml")
    machine.succeed("sed -i 's,<EncoderAppPath>.*</EncoderAppPath>,<EncoderAppPath>/FAKE/bin/ffmpeg</EncoderAppPath>,g' /var/lib/jellyfin/config/encoding.xml")
    stop_jf()
    start_jf()

    with subtest("should reset to real ffmpeg"):
        machine.fail("grep -q '/FAKE/bin/ffmpeg' /var/lib/jellyfin/config/encoding.xml")
        machine.succeed("grep -q '/nix/store/.*/bin/ffmpeg' /var/lib/jellyfin/config/encoding.xml")
  '';
}
