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
  perSystem = { builders, config, filters, pkgs, self', ... }:
  let
    inherit (self'.packages) nix-super;

    pins = import ./sources;
  in
  {
    packages = filters.doFilter filters.packages rec {

      cinny = pkgs.callPackage ./web-apps/cinny { inherit pins; };

      consul = pkgs.callPackage ./servers/consul { };

      excalidraw = pkgs.callPackage ./web-apps/excalidraw {
        inherit pins;
        inherit (builders) mkNpinsSource;
      };

      graf = pkgs.callPackage ./tools/graf { };

      ipfs = pkgs.callPackage ./networking/ipfs { };

      npins = pkgs.npins.override {
        nix = nix-super;
        nix-prefetch-git = pkgs.nix-prefetch-git.override {
          nix = nix-super;
        };
      };

      openbao = pkgs.callPackage ./projects/openbao { };

      opentelemetry-java-agent-bin = pkgs.callPackage ./monitoring/opentelemetry-java-agent-bin { };

      out-of-your-element = pkgs.callPackage ./servers/out-of-your-element { };

      pin = pkgs.callPackage ./tools/pin {
        inherit npins;
        nix = nix-super;
      };

      searxng = pkgs.callPackage ./web-apps/searxng {
        inherit pins;
        inherit (builders) mkNpinsSource;
      };

      stevenblack-hosts = pkgs.callPackage ./data/stevenblack {
        inherit pins;
        inherit (builders) mkNpinsSource;
      };

      void = pkgs.callPackage ./tools/void { };
    };

    projectShells = {
      default = let
        flakePkgs = self'.packages;
      in {
        tools = with flakePkgs; [
          agenix
          graf
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
