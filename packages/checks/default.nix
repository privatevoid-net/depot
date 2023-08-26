{ self, ... }:

{
  perSystem = { filters, pkgs, self', timeTravel', ... }: {
    checks = filters.doFilter filters.checks {
      keycloak = pkgs.callPackage ./keycloak-custom-jre.nix {
        jre = self'.packages.jre17_standard;
      };

      patroni = pkgs.callPackage ./patroni.nix {
        inherit (self) nixosModules;
        inherit (self'.packages) postgresql;
      };
      patroni-migration = pkgs.callPackage ./patroni-migration.nix {
        previous = timeTravel' "486161b78e45e94a6f314b65bb05080605f0cd01";
        inherit (self) nixosModules;
        inherit (self'.packages) postgresql;
      };
      searxng = pkgs.callPackage ./searxng.nix {
        inherit (self'.packages) searxng;
      };
      tempo = pkgs.callPackage ./tempo.nix {
        inherit (self'.packages) tempo;
      };
    };
  };
}
