{ config, lib, depot, tools, ... }:
let
  inherit (depot.reflection) interfaces;
in
{
  services.jitsi-meet = {
    enable = true;
    hostName = "meet.${tools.meta.domain}";
    nginx.enable = true;
    jicofo.enable = true;
    videobridge.enable = true;
    prosody.enable = true;
    config = {
      p2p.enabled = false;
      startAudioOnly = true;
    };
  };
  services.jitsi-videobridge = {
    openFirewall = true;
    apis = [ "colibri" "rest" ];
    config.videobridge = {
      ice = {
        tcp.port = 7777;
      };
      stats.transports = [
        { type = "muc"; }
        { type = "colibri"; }
      ];
    };
    nat = lib.optionalAttrs interfaces.primary.isNat {
      localAddress = interfaces.primary.addr;
      publicAddress = interfaces.primary.addrPublic;
    };
  };
  services.nginx.virtualHosts."meet.${tools.meta.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."=/images/watermark.svg" = {
      return = "200";
    };
  };
  systemd.services = lib.genAttrs [ "jicofo" "jitsi-meet-init-secrets" "jitsi-videobridge2" "prosody" ] (_: {
    serviceConfig = {
      Slice = "communications.slice";
    };
  });
  boot.kernel.sysctl."net.core.rmem_max" = lib.mkForce 10485760;
}
