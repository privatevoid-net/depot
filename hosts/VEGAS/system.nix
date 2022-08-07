{ aspect, config, hosts, inputs, lib, pkgs, tools, ... }:

{
  imports =
    [
      # Hardware
      ./hardware-configuration.nix

      # Plumbing
      ./modules/database
      ./modules/nginx
      ./modules/oauth2-proxy
      ./modules/redis
      ./modules/virtualisation
      inputs.agenix.nixosModules.age
      inputs.mms.module

      # Services
      ./services/api
      ./services/backbone-routing
      ./services/bitwarden
      ./services/fbi
      ./services/gitlab
      ./services/hydra
      ./services/ipfs
      ./services/jokes
      ./services/nextcloud
      ./services/nfs
      ./services/mail
      ./services/matrix
      ./services/minecraft
      ./services/monitoring
      ./services/nix/binary-cache.nix
      ./services/nix/nar-serve.nix
      ./services/object-storage
      ./services/searxng
      ./services/sso
      ./services/uptime-kuma
      ./services/vault
      ./services/warehouse
      ./services/websites
      ./services/wireguard-server
      aspect.modules.hercules-ci-agent
      aspect.modules.hyprspace
      aspect.modules.nix-builder
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

  containers.soda = {
    path = inputs.self.nixosConfigurations.soda.config.system.build.toplevel;
    privateNetwork = true;
    hostBridge = "vmdefault";
    localAddress = "${hosts.soda.interfaces.primary.addr}/24";
    autoStart = true;
    bindMounts.sodaDir = {
      hostPath = "/srv/storage/www/soda";
      mountPoint = "/soda";
      isReadOnly = false;
    };
  };
  systemd.services."container@soda".after = [ "libvirtd.service" "sys-devices-virtual-net-vmdefault.device" ];
}
