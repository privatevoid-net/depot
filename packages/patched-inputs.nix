{
  perSystem = { filters, inputs', lib, pkgs, ... }:

  let
    tools = import ./lib/tools.nix;
    packages = builtins.mapAttrs (_: v: v.packages) inputs';
  in with tools;

  {
    packages = filters.doFilter filters.packages rec {
      nix-super = packages.nix-super.nix;

      agenix = packages.agenix.agenix.override { nix = nix-super; };
    };
  };
}
