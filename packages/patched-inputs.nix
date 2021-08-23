let tools = import ./lib/tools.nix;
in with tools;
{ inputs, pkgs, ... }: rec {
  deploy-rs = inputs.deploy-rs.packages.x86_64-linux.deploy-rs;

  nix-super = inputs.nix-super.defaultPackage.x86_64-linux;

  agenix = inputs.agenix.packages.x86_64-linux.agenix.override { nix = nix-super; };
}
