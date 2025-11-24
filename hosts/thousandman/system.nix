{ config, depot, ... }:

let
  inherit (config.reflection.interfaces) primary;
in

{
  imports = [
    ./hardware-configuration.nix

    depot.inputs.agenix.nixosModules.age

    depot.nixosModules.serverBase

    # depot.nixosModules.hyprspace
  ];

  zramSwap.enable = true;

  networking.hostName = "thousandman";
  networking.nameservers = [ depot.hours.VEGAS.interfaces.vstub.addr ];

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  time.timeZone = "Europe/Berlin";

  networking = {
    defaultGateway = "159.195.32.1";
    useDHCP = false;
    dhcpcd.enable = false;
    interfaces = {
      ${primary.link} = {
        ipv4.addresses = [
          { address = primary.addr; prefixLength = 22; }
        ];
      };
    };
  };

  system.stateVersion = "25.11";
}
