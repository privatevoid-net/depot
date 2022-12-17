{ nixosTest, keycloak, jre }:

nixosTest {
  name = "keycloak";
  nodes.machine.services.keycloak = {
    enable = true;
    package = keycloak.override { inherit jre; };
    database.passwordFile = builtins.toFile "keycloak-test-password" "kcnixostest1234";
    settings = {
      proxy = "edge";
      hostname = "keycloak.local";
    };
  };
  testScript = ''
    machine.wait_for_unit("keycloak.service")
    machine.wait_for_open_port(80)
    machine.succeed("curl --fail http://127.0.0.1:80")
  '';
}
