{ pkgs, aspect, hosts, tools, ... }:

{
  imports = with aspect; [
    modules.fail2ban
    modules.nix-config-server
    modules.sss
    ./soda.nix
  ] ++ sets.base ++ sets.networking;

  boot.isContainer = true;

  networking.useDHCP = false;

  networking.interfaces.eth0.useDHCP = true;

  networking.nameservers = [ hosts.VEGAS.interfaces.vstub.addr ];

  networking.resolvconf.extraConfig = "local_nameservers='${hosts.VEGAS.interfaces.vstub.addr}'";

  networking.hostName = "soda";

  time.timeZone = "Europe/Helsinki";

  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh.enable = true;

  system.stateVersion = "21.11";
}
