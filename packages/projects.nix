{ inputs, self, ... }:

{
  perSystem = { filters, pkgs, self', ... }:
  let
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

      ./networking/hyprspace/project.nix
      ./networking/ipfs-cluster/project.nix
      ./servers/reflex-cache/project.nix
      ./websites/landing/project.nix
      ./websites/stop-using-nix-env/project.nix
    ];
    packages = filters.doFilter filters.packages rec {
      cinny = pkgs.callPackage ./web-apps/cinny { inherit pins; };

      excalidraw = let
        dream = dream2nix.dream2nix-interface.makeOutputs {
          source = pins.excalidraw;
        };
        inherit (dream.packages) excalidraw;
      in
        excalidraw // { webroot = "${excalidraw}/${excalidraw.webPath}"; };

      uptime-kuma = let
        dream = dream2nix.dream2nix-interface.makeOutputs {
          source = pins.uptime-kuma;
        };
        inherit (dream.packages) uptime-kuma;
      in
        uptime-kuma;

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

      privatevoid-smart-card-ca-bundle = pkgs.callPackage ./data/privatevoid-smart-card-certificate-authority-bundle.nix { };

      searxng = pkgs.callPackage ./web-apps/searxng { inherit pins; };

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
          pkgs.deadnix
          pkgs.statix
        ];

        env.NPINS_DIRECTORY.eval = "$REPO_ROOT/packages/sources";
      };
    };
  };
}