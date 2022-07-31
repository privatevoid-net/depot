{
  perSystem = { filters, inputs', ... }:

  let
    tools = import ./lib/tools.nix;
    packages = builtins.mapAttrs (_: v: v.packages) inputs';
  in with tools;

  {
    packages = filters.doFilter filters.packages rec {
      inherit (packages.deploy-rs) deploy-rs;

      nix-super = packages.nix-super.nix;

      agenix = packages.agenix.agenix.override { nix = nix-super; };

      hercules-ci-agent = packages.hercules-ci-agent.hercules-ci-agent;

      hci = packages.hercules-ci-agent.hercules-ci-cli;
    };
  };
}