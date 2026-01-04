{ config, depot, ... }:

let
  inherit (config.reflection.interfaces) primary;
in

{
  imports = [
    ./hardware-configuration.nix

    depot.nixosModules.serverBase

    # depot.nixosModules.hyprspace
  ];

  zramSwap.enable = true;

  networking.hostName = "thousandman";
  networking.nameservers = [ depot.hours.VEGAS.interfaces.vstub.addr ];

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  time.timeZone = "Europe/Berlin";
}
