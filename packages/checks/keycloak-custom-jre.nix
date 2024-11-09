{ nixosTest, keycloak }:

nixosTest {
  name = "keycloak";
  nodes.machine.services.keycloak = {
    enable = true;
    package = keycloak;
    database.passwordFile = builtins.toFile "keycloak-test-password" "kcnixostest1234";
    settings = {
      http-enabled = true;
      proxy-headers = "xforwarded";
      hostname = "keycloak.local";
    };
  };
  testScript = ''
    machine.wait_for_unit("keycloak.service")
    machine.wait_for_open_port(80)
    machine.succeed("curl --fail http://127.0.0.1:80")
  '';
}
