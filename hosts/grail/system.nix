{ depot, ... }:

let
  inherit (depot.reflection.interfaces) primary;
in

{
  imports = [
    ./hardware-configuration.nix

    depot.inputs.agenix.nixosModules.age

    depot.nixosModules.serverBase

    depot.nixosModules.hyprspace
  ];

  zramSwap.enable = true;

  networking.hostName = "grail";
  networking.nameservers = [ depot.hours.VEGAS.interfaces.vstub.addr ];

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  time.timeZone = "Europe/Helsinki";

  networking = {
    defaultGateway = "172.31.1.1";
    useDHCP = false;
    dhcpcd.enable = false;
    interfaces = {
      ${primary.link} = {
        ipv4.addresses = [
          { address = primary.addr; prefixLength = 32; }
        ];
        ipv4.routes = [ { address = "172.31.1.1"; prefixLength = 32; } ];
      };
    };
  };

  system.stateVersion = "23.05";
}
