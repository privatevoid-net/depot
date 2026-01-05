{ config, depot, ... }:

{
  imports =
    [
      # Hardware
      ./hardware-configuration.nix

      depot.nixosModules.hyprspace
      depot.nixosModules.nix-builder

      depot.nixosModules.serverBase
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "prophet";
  networking.nameservers = [ depot.hours.VEGAS.interfaces.vstub.addr ];

  time.timeZone = "Europe/Zurich";

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  system.stateVersion = "21.11";

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";
}

