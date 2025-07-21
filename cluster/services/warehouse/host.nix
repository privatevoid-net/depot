{ config, depot, lib, ... }:
with depot.lib.nginx;
{
  # TODO: not a whole lot to configure, maybe add some autoconfig stuff
  services.jellyfin = {
    enable = true;
  };
  services.nginx.virtualHosts."warehouse.${depot.lib.meta.domain}" = lib.mkMerge [
    (vhosts.proxy "http://127.0.0.1:8096")
    {
      locations."/".extraConfig = ''
        proxy_buffering off;
      '';
      locations."/socket" = {
        inherit (config.services.nginx.virtualHosts."warehouse.${depot.lib.meta.domain}".locations."/") proxyPass;
        proxyWebsockets = true;
      };
      # TODO: video cache
    }
  ];

  hardware.graphics = {
    enable = true;
  };
  systemd.services.jellyfin = {
    # if EncoderAppPath is manually set in the web UI, it can never be updated through --ffmpeg
    preStart = "test ! -e /var/lib/jellyfin/config/encoding.xml || sed -i '/<EncoderAppPath>/d' /var/lib/jellyfin/config/encoding.xml";
    serviceConfig = {
      # allow access to GPUs for hardware transcoding
      DeviceAllow = lib.mkForce "char-drm";
      BindPaths = lib.mkForce "/dev/dri";
      # to allow restarting from web ui
      Restart = lib.mkForce "always";

      Slice = "mediaplayback.slice";
    };
  };
}
