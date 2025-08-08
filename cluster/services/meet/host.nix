{ config, lib, depot, pkgs, ... }:
let
  inherit (config) links;

  inherit (config.reflection) interfaces;
in
{
  links = {
    jitsi-exporter.protocol = "http";
  };

  services.jitsi-meet = {
    enable = true;
    hostName = "meet.${depot.lib.meta.domain}";
    nginx.enable = true;
    jicofo.enable = true;
    videobridge.enable = true;
    prosody.enable = true;
    config = {
      p2p.enabled = false;
      startAudioOnly = true;
      openBridgeChannel = "websocket";
    };
  };
  services.jitsi-videobridge = {
    openFirewall = true;
    colibriRestApi = true;
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

  # https://github.com/NixOS/nixpkgs/pull/429837
  services.prosody.package = pkgs.prosody;

  services.nginx.virtualHosts."meet.${depot.lib.meta.domain}" = {
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

  services.prometheus.exporters.jitsi = {
    enable = true;
    interval = "60s";
    listenAddress = links.jitsi-exporter.ipv4;
    inherit (links.jitsi-exporter) port;
  };

  services.alloy.metrics.targets.jitsi = {
    address = links.jitsi-exporter.tuple;
    labels.instance = config.services.jitsi-meet.hostName;
  };
}
