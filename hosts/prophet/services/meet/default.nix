{ config, lib, hosts, tools, ... }:
let
  host = hosts.${config.networking.hostName};
  inherit (host) interfaces;

  isNAT = interfaces.primary ? addrPublic;
in
{
  services.jitsi-meet = {
    enable = true;
    hostName = "meet.${tools.meta.domain}";
    nginx.enable = true;
    jicofo.enable = true;
    videobridge.enable = true;
    prosody.enable = true;
    config.p2p.enabled = false;
  };
  services.jitsi-videobridge = {
    openFirewall = true;
    nat = lib.optionalAttrs isNAT {
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
      LogNamespace = "meet";
      Slice = "communications.slice";
    };
  });
  boot.kernel.sysctl."net.core.rmem_max" = lib.mkForce 10485760;
}
