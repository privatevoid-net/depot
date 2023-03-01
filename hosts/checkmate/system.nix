{ aspect, inputs, hosts, ... }:

{
  imports =
    [
      # Hardware
      ./hardware-configuration.nix

      inputs.agenix.nixosModules.age

      aspect.modules.hyprspace
      aspect.modules.sss
    ]
    ++ aspect.sets.server;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "checkmate";
  networking.nameservers = [ hosts.VEGAS.interfaces.vstub.addr ];

  time.timeZone = "Europe/Zurich";

  networking.useDHCP = false;
  networking.interfaces.ens3.useDHCP = true;

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";

  system.stateVersion = "21.11";

}

