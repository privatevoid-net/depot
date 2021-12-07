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
      ./services/cdn-shield
      ./services/dns
      ./services/fbi
      ./services/bitwarden
      # TODO: fix this one
      ./services/forum
      ./services/git
      ./services/hydra
      ./services/hyprspace
      ./services/ipfs
      ./services/jokes
      ./services/meet
      ./services/nextcloud
      ./services/nfs
      ./services/mail
      ./services/matrix
      ./services/nix/binary-cache.nix
      ./services/nix/nar-serve.nix
      ./services/object-storage
      ./services/openvpn
      ./services/sso
      ./services/vault
      ./services/warehouse
      ./services/websites
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

  nixpkgs.config.allowUnfree = true;
  services.minecraft-server = let
    modpack = fetchTarball {
      url = "https://bafybeiar4mnqvbwkb4glerj6yibccgscbff7nzeojf6px3oapxn7f7hymq.ipfs.privatevoid.net/modpack.tar.gz";
      sha256 = "sha256:1iqd6mlknbq4r3iqpfsibp8h2kknaaqkqarnw03z2s61ivsqq7lc";
    };
  in {
    enable = true;
    eula = true;
    openFirewall = true;
    package = pkgs.minecraft-server.overrideAttrs (_: {
      version = "forge-1.12.2";
      src = "${modpack}/forge-1.12.2-14.23.5.2796-universal.jar"; # HACK
    });
  };
  systemd.services.minecraft-server.path = [ pkgs.jre8 ];
  systemd.services.minecraft-server.serviceConfig = {
    ExecStart = lib.mkForce "/var/lib/minecraft/start.sh";
  };

  users.users.minecraft.group = lib.mkForce "minecraft-sftp";
  users.groups.minecraft-sftp = {};
  services.openssh.extraConfig = ''
    Match Group minecraft-sftp
      ChrootDirectory /srv/minecraft-cc-sftp
      ForceCommand internal-sftp -u 0002
      AllowTcpForwarding no
      X11Forwarding no
  '';
}
