{ aspect, inputs, config, pkgs, ... }:

{
  imports =
    [
      # Hardware
      ./hardware-configuration.nix

      inputs.agenix.nixosModules.age

    ]
    ++ aspect.sets.server;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "prophet";

  time.timeZone = "Europe/Zurich";

  networking.useDHCP = false;
  networking.interfaces.enp0s3.useDHCP = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.opc = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;

  system.stateVersion = "21.11";

}

