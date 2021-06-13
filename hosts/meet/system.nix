{ config, pkgs, modulesPath, aspect, inputs, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
    inputs.agenix.nixosModules.age
  ]
  ++ (import ../../users "server").groups.admin
  ++ aspect.sets.server
  ++ (with aspect.modules; [ ]);

  networking.hostName = "meet";
  networking.firewall.enable = false;

  nix.trustedUsers = [ "root" "@wheel" ];

  security.sudo.wheelNeedsPassword = false;

  services.jitsi-meet = {
    enable = true;
    hostName = "meet.privatevoid.net";
    nginx.enable = true;
    jicofo.enable = true;
    videobridge.enable = true;
    prosody.enable = true;
    config.p2p.enabled = false;
  };
  services.jitsi-videobridge = {
    nat.publicAddress = "95.216.8.12";
    nat.localAddress = "10.10.1.204";
  };
  services.nginx.virtualHosts."meet.privatevoid.net" = {
    enableACME = false;
    forceSSL = false;
    locations."=/images/watermark.svg" = {
      return = "200";
    };
  };
  environment.noXlibs = false;
}
