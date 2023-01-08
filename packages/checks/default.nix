{ self, ... }:

{
  perSystem = { filters, pkgs, self', ... }: {
    checks = filters.doFilter filters.checks {
      keycloak = pkgs.callPackage ./keycloak-custom-jre.nix {
        jre = self'.packages.jre17_standard;
      };

      patroni = pkgs.callPackage ./patroni.nix {
        patroniModule = self.nixosModules.patroni;
      };
      tempo = pkgs.callPackage ./tempo.nix {
        inherit (self'.packages) tempo;
      };
    };
  };
}
