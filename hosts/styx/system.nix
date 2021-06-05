{ config, pkgs, modulesPath, aspect, inputs, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
    inputs.agenix.nixosModules.age
  ]
  ++ (import ../../users "server").groups.admin
  ++ aspect.sets.server
  ++ (with aspect.modules; [ hydra ]);

  networking.hostName = "styx";
  networking.firewall.enable = false;

  nix.trustedUsers = [ "root" "@wheel" ];

  security.sudo.wheelNeedsPassword = false;
}
