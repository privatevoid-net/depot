{ config, hosts, ... }:
{
  services.fail2ban = {
    enable = true;
    banaction = "iptables-multiport[blocktype=DROP]";
    jails.sshd = ''
      enabled = true
      port = 22
      mode = aggressive
    '';
    ignoreIP = [
      "10.0.0.0/8"
      hosts.${config.networking.hostName}.interfaces.primary.addr
    ];
    bantime-increment = {
      enable = true;
    };
  };
}
