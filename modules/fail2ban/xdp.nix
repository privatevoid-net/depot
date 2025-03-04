{ config, pkgs, ... }:
let
  inherit (pkgs) xdp-tools;
in
{
  systemd.services."xdp-filter@" = {
    description = "XDP Filter on %I";
    after = [ "network.target" ];
    wants = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${xdp-tools}/bin/xdp-filter load %i -f ipv4 -m skb";
      ExecStop = "${xdp-tools}/bin/xdp-filter unload %i";
      RemainAfterExit = true;
    };
  };
  environment.etc."fail2ban/action.d/xdp.conf".text = ''
    [Definition]
    actionstart = systemctl start xdp-filter@${config.reflection.interfaces.primary.link}.service
    actionstop = systemctl stop xdp-filter@${config.reflection.interfaces.primary.link}.service
    actionban = ${xdp-tools}/bin/xdp-filter ip --mode src <ip>
    actionunban = ${xdp-tools}/bin/xdp-filter ip --remove --mode src <ip>
  '';
}
