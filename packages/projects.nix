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

      openbao = pkgs.callPackage ./projects/openbao { };

      out-of-your-element = pkgs.callPackage ./servers/out-of-your-element { };

      pin = pkgs.callPackage ./tools/pin {
        nix = nix-super;
      };

      quickie = pkgs.callPackage ./servers/quickie { };
      
      stevenblack-hosts = pkgs.callPackage ./data/stevenblack {
        inherit pins;
        inherit (builders) mkNpinsSource;
      };

      void = pkgs.callPackage ./tools/void { };
      
      zerofs = pkgs.callPackage ./projects/zerofs { };
    };

    projectShells = {
      default = let
        flakePkgs = self'.packages;
      in {
        tools = with flakePkgs; [
          agenix
          graf
          pin
          void
          pkgs.deadnix
          pkgs.statix
          pkgs.npins
        ];

        env.NPINS_DIRECTORY.eval = "$REPO_ROOT/packages/sources";
      };
    };
  };
}
