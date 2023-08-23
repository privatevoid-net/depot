{ self, ... }:

{
  perSystem = { filters, pkgs, self', ... }: {
    checks = filters.doFilter filters.checks {
      keycloak = pkgs.callPackage ./keycloak-custom-jre.nix {
        jre = self'.packages.jre17_standard;
      };

      patroni = pkgs.callPackage ./patroni.nix {
        inherit (self) nixosModules;
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
