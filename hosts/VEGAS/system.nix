{ aspect, config, inputs, lib, pkgs, tools, ... }:

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

      # Services
      ./services/api
      ./services/backbone-routing
      ./services/bitwarden
      ./services/blog
      ./services/dns
      ./services/fbi
      ./services/gitlab
      ./services/hydra
      ./services/ipfs
      ./services/jokes
      ./services/nextcloud
      ./services/nfs
      ./services/mail
      ./services/matrix
      ./services/nix/binary-cache.nix
      ./services/nix/nar-serve.nix
      ./services/object-storage
      ./services/openvpn
      ./services/sips
      ./services/sso
      ./services/vault
      ./services/warehouse
      ./services/websites
      aspect.modules.hyprspace
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
}
