{ filters, inputs', pkgs, self', ... }:
let
  inherit (pkgs) nixosTest;
in
{
  checks = filters.doFilter filters.checks {
    keycloak = nixosTest {
      name = "keycloak";
      nodes.machine.services.keycloak = {
        enable = true;
        package = pkgs.keycloak.override { jre = self'.packages.jre17_standard; };
        database.passwordFile = builtins.toFile "keycloak-test-password" "kcnixostest1234";
        settings = {
          proxy = "edge";
          hostname = "keycloak.local";
        };
      };
      testScript = ''
        machine.wait_for_unit("keycloak.service")
        machine.wait_for_open_port("80")
        machine.succeed("curl --fail http://127.0.0.1:80")
      '';
    };
  };
}
