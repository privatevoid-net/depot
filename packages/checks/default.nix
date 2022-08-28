{ filters, inputs', pkgs, self', ... }:
{
  checks = filters.doFilter filters.checks {
    keycloak = pkgs.callPackage ./keycloak-custom-jre.nix {
      jre = self'.packages.jre17_standard;
    };
  };
}
