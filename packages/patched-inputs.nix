let tools = import ./lib/tools.nix;
in with tools;
{ inputs, pkgs, system, ... }: rec {
  inherit (inputs.deploy-rs.packages.${system}) deploy-rs;

  nix-super = inputs.nix-super.defaultPackage.${system};

  agenix = inputs.agenix.packages.${system}.agenix.override { nix = nix-super; };
}
