{ depot, ... }:

{
  imports =
    [
      # Hardware
      ./hardware-configuration.nix

      depot.inputs.agenix.nixosModules.age

      depot.nixosModules.hyprspace
      depot.nixosModules.sss
      depot.nixosModules.serverBase
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thunderskin";
  networking.nameservers = [ depot.config.hours.VEGAS.interfaces.vstub.addr ];

  time.timeZone = "Europe/Zurich";

  networking.useDHCP = false;
  networking.interfaces.ens3.useDHCP = true;

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";

  system.stateVersion = "22.11";
}