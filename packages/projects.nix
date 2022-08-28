{ inputs, self, ... }:

{
  perSystem = { filters, inputs', pkgs, self', system, ... }:
  let
    inherit (pkgs) lib;
    inherit (self'.packages) nix-super;

    pins = import ./sources;

    dream2nix = inputs.dream2nix.lib2.init {
      inherit pkgs;
      config = {
        projectRoot = ./.;
        overridesDirs = [ ./dream2nix-overrides ];
      };
    };
    poetry2nix = pkgs.poetry2nix.overrideScope' (final: prev: {
      defaultPoetryOverrides = prev.defaultPoetryOverrides.extend (import ./poetry2nix-overrides);
    });

  in
  {
    _module.args = { inherit inputs self; };

    imports = [
      ./checks
      ./modules/devshell.nix
      ./build-support

      ./websites/landing/project.nix
      ./websites/stop-using-nix-env/project.nix
    ];
    packages = filters.doFilter filters.packages rec {
      cinny = pkgs.callPackage ./web-apps/cinny { inherit pins; };

      excalidraw = let
        dream = dream2nix.makeOutputs {
          source = pins.excalidraw;
        };
        inherit (dream.packages) excalidraw;
      in
        excalidraw;

      uptime-kuma = let
        dream = dream2nix.makeOutputs {
          source = pins.uptime-kuma;
        };
        inherit (dream.packages) uptime-kuma;
      in
        uptime-kuma;

      gohugo-theme-ananke = pkgs.callPackage ./themes/gohugo-theme-ananke { inherit pins; };

      grafana = pkgs.callPackage ./monitoring/grafana { };

      hyprspace = pkgs.callPackage ./networking/hyprspace { iproute2mac = null; };

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

      privatevoid-smart-card-ca-bundle = pkgs.callPackage ./data/privatevoid-smart-card-certificate-authority-bundle.nix { };

      reflex-cache = poetry2nix.mkPoetryApplication {
        projectDir = ./servers/reflex-cache;
        meta.mainProgram = "reflex";
      };

      searxng = pkgs.callPackage ./web-apps/searxng { inherit pins; };

      sips = pkgs.callPackage ./servers/sips { };

      stevenblack-hosts = pkgs.callPackage ./data/stevenblack { inherit pins; };
    };

    projectShells = {
      default = let
        flakePkgs = self'.packages;
      in {
        tools = with flakePkgs; [
          agenix
          deploy-rs
          dvc
          npins
          pin
        ];

        env.NPINS_DIRECTORY.eval = "$REPO_ROOT/packages/sources";
      };
      reflex-cache = let
        inherit (self'.packages) reflex-cache;
      in {
        packages = [
          reflex-cache.dependencyEnv
        ];
      
        tools = [
          pkgs.poetry
        ];

        env.PYTHON = reflex-cache.dependencyEnv.interpreter;
      };
    };
  };
}