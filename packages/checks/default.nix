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
        exampleData = pkgs.fetchurl {
          name = "omdb-2022-10-18.dump";
          url = "https://github.com/credativ/omdb-postgresql/releases/download/2022-10-18/omdb.dump";
          hash = "sha256-7ENUTHrpdrB44AyHT3aB44AFY/vFsKTzt70Fnb9ynq8=";
        };
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
