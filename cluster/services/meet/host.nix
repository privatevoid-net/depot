{ config, lib, depot, ... }:
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

  services.grafana-agent.settings.metrics.configs = lib.singleton {
    name = "metrics-jitsi";
    scrape_configs = lib.singleton {
      job_name = "jitsi";
      static_configs = lib.singleton {
        targets = lib.singleton links.jitsi-exporter.tuple;
        labels.instance = config.services.jitsi-meet.hostName;
      };
    };
  };
}
