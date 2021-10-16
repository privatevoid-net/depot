{ aspect, config, inputs, lib, pkgs, tools, ... }:

{
  imports =
    [
      # Hardware
      ./hardware-configuration.nix
    ]
    # TODO: fix users
    # ++ (import ../../users "server").groups.admin
    ++ aspect.sets.backbone;

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";


  networking.hostName = "VEGAS";
  networking.domain = "backbone.${tools.meta.domain}";

  time.timeZone = "Europe/Helsinki";

  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  networking.firewall.enable = true;

  system.stateVersion = "21.05";
  services.openssh.passwordAuthentication = false;

  systemd.additionalUpstreamSystemUnits = [
    "systemd-journald@.service"
    "systemd-journald@.socket"
    "systemd-journald-varlink@.socket"
  ];
}
