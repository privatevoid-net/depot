{ inputs, pkgs, ... }:

{
  systemd.targets.maintenance = {
    unitConfig.AllowIsolate = true;
    wants = [
      "basic.target"
      "getty.target"
      "network.target"
      "network-online.target"
      "sshd.service"
      "fail2ban.service"
      "hyprspace.service"
      "dbus.service"
    ];
  };
}
