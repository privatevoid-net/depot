{ config, depot, ... }:

{
  imports =
    [
      # Hardware
      ./hardware-configuration.nix

      # Plumbing
      ./modules/redis
      ./modules/virtualisation
      depot.inputs.mms.module

      # Services
      ./services/backbone-routing
      ./services/minecraft
      depot.nixosModules.hyprspace
      depot.nixosModules.nix-builder

      depot.nixosModules.backboneBase
    ];
    # TODO: fix users
    # ++ (import ../../users "server").groups.admin

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";


  networking.hostName = "VEGAS";
  networking.domain = "backbone.${depot.lib.meta.domain}";

  time.timeZone = "Europe/Helsinki";

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  networking.firewall = {
    enable = true;
    extraCommands = let
      privateIp4Ranges = [
          "10.0.0.0/8"
          "100.64.0.0/10"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "192.0.0.0/24"
          "192.0.2.0/24"
          "192.168.0.0/16"
          "198.18.0.0/15"
          "198.51.100.0/24"
          "203.0.113.0/24"
          "240.0.0.0/4"
      ];

      privateIp6Ranges = [
        "100::/64"
        "2001:2::/48"
        "2001:db8::/32"
        "fc00::/7"
        "fe80::/10"
      ];

      mkRules = ipt: ranges: map (x: "${ipt} -I nixos-fw 1 -d ${x} -o ${config.reflection.interfaces.primary.link} -j DROP") ranges;

      rules4 = mkRules "iptables" privateIp4Ranges;

      rules6 = mkRules "ip6tables" privateIp6Ranges;
    in builtins.concatStringsSep "\n" (rules4 ++ rules6);
  };

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";

  system.stateVersion = "21.05";
  services.openssh.settings.PasswordAuthentication = false;
}
