{ config, depot, tools, ... }:

{
  imports =
    [
      # Hardware
      ./hardware-configuration.nix

      # Plumbing
      ./modules/database
      ./modules/oauth2-proxy
      ./modules/redis
      ./modules/virtualisation
      depot.inputs.agenix.nixosModules.age
      depot.inputs.mms.module

      # Services
      ./services/api
      ./services/backbone-routing
      ./services/bitwarden
      ./services/cdn-shield
      ./services/fbi
      ./services/gitlab
      ./services/jokes
      ./services/mail
      ./services/minecraft
      ./services/nix/binary-cache.nix
      ./services/nix/nar-serve.nix
      ./services/reflex
      ./services/sso
      ./services/vault
      ./services/warehouse
      ./services/websites
      ./services/wireguard-server
      depot.nixosModules.hyprspace
      depot.nixosModules.nix-builder

      depot.nixosModules.backboneBase
    ];
    # TODO: fix users
    # ++ (import ../../users "server").groups.admin

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

      mkRules = ipt: ranges: map (x: "${ipt} -I nixos-fw 1 -d ${x} -o ${depot.reflection.interfaces.primary.link} -j DROP") ranges;

      rules4 = mkRules "iptables" privateIp4Ranges;

      rules6 = mkRules "ip6tables" privateIp6Ranges;
    in builtins.concatStringsSep "\n" (rules4 ++ rules6);
  };

  system.stateVersion = "21.05";
  services.openssh.settings.PasswordAuthentication = false;

  containers.soda = {
    path = depot.nixosConfigurations.soda.config.system.build.toplevel;
    privateNetwork = true;
    hostBridge = "vmdefault";
    localAddress = "${depot.config.hours.soda.interfaces.primary.addr}/24";
    autoStart = true;
    bindMounts.sodaDir = {
      hostPath = "/srv/storage/www/soda";
      mountPoint = "/soda";
      isReadOnly = false;
    };
  };
  systemd.services."container@soda".after = [ "libvirtd.service" "sys-devices-virtual-net-vmdefault.device" ];
}
