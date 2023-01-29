{
  perSystem = { filters, inputs', lib, pkgs, ... }:

  let
    tools = import ./lib/tools.nix;
    packages = builtins.mapAttrs (_: v: v.packages) inputs';
  in with tools;

  {
    packages = filters.doFilter filters.packages rec {
      inherit (packages.deploy-rs) deploy-rs;

      nix-super = packages.nix-super.nix;

      agenix = packages.agenix.agenix.override { nix = nix-super; };

      # hci-agent's build code does some funny shenanigans
      hercules-ci-agent = let
        original = packages.hercules-ci-agent.hercules-ci-agent;
        patchedNix = (patch original.nix "patches/extra/hercules-ci-agent/nix").overrideAttrs (old: rec {
          name = "nix-${version}";
          version = "${original.nix.version}_hci2";
          postUnpack = ''
            ${old.postUnpack or ""}
            echo -n "${version}" > .version
          '';
        });
        forcePatchNix = old: {
          buildInputs = (lib.remove original.nix old.buildInputs) ++ [ patchedNix ];
          passthru = old.passthru // {
            nix = patchedNix;
          };
        };
        patchDeps = lib.const rec {
          hercules-ci-cnix-store = packages.hercules-ci-agent.internal-hercules-ci-cnix-store.override (lib.const {
            nix = patchedNix;
          });
          hercules-ci-cnix-expr = packages.hercules-ci-agent.internal-hercules-ci-cnix-expr.override (lib.const {
            nix = patchedNix;
            inherit hercules-ci-cnix-store;
          });
          cachix = pkgs.haskellPackages.cachix.override (lib.const {
            nix = patchedNix;
            inherit hercules-ci-cnix-store;
          });
        };
      in (original.override patchDeps).overrideAttrs forcePatchNix;

      hci = packages.hercules-ci-agent.hercules-ci-cli;
    };
  };
}