{ config, ... }:
{
  services.fail2ban = {
    enable = true;
    banaction = "iptables-multiport[blocktype=DROP]";
    jails.sshd.settings.mode = "aggressive";
    ignoreIP = [
      "10.0.0.0/8"
      config.reflection.interfaces.primary.addr
    ];
    bantime-increment = {
      enable = true;
      maxtime = "48h";
    };
  };
}
