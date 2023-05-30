{ lib, inputs, self, ... }:

{
  imports = [
    ./checks
    ./modules/devshell.nix
    ./build-support

    ./networking/hyprspace/project.nix
    ./networking/ipfs-cluster/project.nix
    ./servers/reflex-cache/project.nix
    ./websites/landing/project.nix
    ./websites/stop-using-nix-env/project.nix
  ];
  dream2nix.config = {
    projectRoot = ./.;
    overridesDirs = [ ./dream2nix-overrides ];
  };
  perSystem = { config, filters, pkgs, self', ... }:
  let
    inherit (self'.packages) nix-super;

    pins = import ./sources;
  in
  {
    dream2nix = {
      inputs = filters.doFilter filters.packages {
        uptime-kuma = {
          source = pins.uptime-kuma;
          projects.uptime-kuma = {
            subsystem = "nodejs";
            translator = "package-lock";
          };
        };
        excalidraw = {
          source = pins.excalidraw;
          projects.excalidraw = {
            subsystem = "nodejs";
            translator = "yarn-lock";
          };
        };
      };
    };

    packages = filters.doFilter filters.packages rec {

      cinny = pkgs.callPackage ./web-apps/cinny { inherit pins; };

      excalidraw = let
        inherit (config.dream2nix.outputs.excalidraw.packages) excalidraw;
      in excalidraw // { webroot = "${excalidraw}/${excalidraw.webPath}"; };

      graf = pkgs.callPackage ./tools/graf { };

      grafana = pkgs.callPackage ./monitoring/grafana { };

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

      inherit (config.dream2nix.outputs.uptime-kuma.packages) uptime-kuma;
    };

    projectShells = {
      default = let
        flakePkgs = self'.packages;
      in {
        tools = with flakePkgs; [
          agenix
          deploy-rs
          dvc
          hci
          npins
          pin
          pkgs.deadnix
          pkgs.statix
        ];

        env.NPINS_DIRECTORY.eval = "$REPO_ROOT/packages/sources";
      };
    };
  };
}