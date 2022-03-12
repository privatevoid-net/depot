let tools = import ./lib/tools.nix;
in with tools;
{ inputs, pkgs, ... }: rec {
  inherit (inputs.deploy-rs.packages.${pkgs.system}) deploy-rs;

  nix-super = inputs.nix-super.defaultPackage.${pkgs.system};

  agenix = inputs.agenix.packages.${pkgs.system}.agenix.override { nix = nix-super; };
}
