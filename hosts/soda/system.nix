{ config, depot, ... }:

{
  imports = with depot.nixosModules; [
    containerBase
    fail2ban
    ./soda.nix
  ];

  boot.isContainer = true;

  networking.nameservers = [ depot.hours.VEGAS.interfaces.vstub.addr ];

  networking.resolvconf.extraConfig = "local_nameservers='${depot.hours.VEGAS.interfaces.vstub.addr}'";

  networking.hostName = "soda";

  time.timeZone = "Europe/Helsinki";

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  system.stateVersion = "21.11";
}
