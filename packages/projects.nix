{ lib, inputs, self, ... }:

{
  imports = [
    ./checks
    ./modules/devshell.nix
    ./build-support

    ./servers/reflex-cache/project.nix
    ./websites/landing/project.nix
    ./websites/stop-using-nix-env/project.nix
  ];
  perSystem = { config, filters, pkgs, self', ... }:
  let
    inherit (self'.packages) nix-super;

    pins = import ./sources;
  in
  {
    packages = filters.doFilter filters.packages rec {

      cinny = pkgs.callPackage ./web-apps/cinny { inherit pins; };

      consul = pkgs.callPackage ./servers/consul { };

      excalidraw = pkgs.callPackage ./web-apps/excalidraw { inherit pins; };

      graf = pkgs.callPackage ./tools/graf { };

      ipfs = pkgs.callPackage ./networking/ipfs { };

      npins = pkgs.callPackage ./tools/npins {
        nix = nix-super;
        nix-prefetch-git = pkgs.nix-prefetch-git.override {
          nix = nix-super;
        };
      };

      opentelemetry-java-agent-bin = pkgs.callPackage ./monitoring/opentelemetry-java-agent-bin { };

      pin = pkgs.callPackage ./tools/pin {
        inherit npins;
        nix = nix-super;
      };

      searxng = pkgs.callPackage ./web-apps/searxng { inherit pins; };

      stevenblack-hosts = pkgs.callPackage ./data/stevenblack { inherit pins; };

      void = pkgs.callPackage ./tools/void { };
    };

    projectShells = {
      default = let
        flakePkgs = self'.packages;
      in {
        tools = with flakePkgs; [
          agenix
          graf
          hci
          npins
          pin
          void
          pkgs.deadnix
          pkgs.statix
        ];

        env.NPINS_DIRECTORY.eval = "$REPO_ROOT/packages/sources";
      };
    };
  };
}
