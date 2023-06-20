{ config, depot, lib, pkgs, tools, ... }:
with tools.nginx;
{
  # TODO: not a whole lot to configure, maybe add some autoconfig stuff
  services.jellyfin = {
    enable = true;
    package = depot.packages.jellyfin;
  };
  services.nginx.virtualHosts."warehouse.${tools.meta.domain}" = lib.mkMerge [
    (vhosts.proxy "http://127.0.0.1:8096")
    {
      locations."/".extraConfig = ''
        proxy_buffering off;
      '';
      locations."/socket" = {
        inherit (config.services.nginx.virtualHosts."warehouse.${tools.meta.domain}".locations."/") proxyPass; 
        proxyWebsockets = true;
      };
      # TODO: video cache
    }
  ];

  hardware.opengl = {
    enable = true;
    package = pkgs.intel-media-driver;
  };
  systemd.services.jellyfin.serviceConfig = {
    # allow access to GPUs for hardware transcoding
    DeviceAllow = lib.mkForce "char-drm";
    BindPaths = lib.mkForce "/dev/dri";
    # to allow restarting from web ui
    Restart = lib.mkForce "always";

    Slice = "mediaplayback.slice";
  };

  fileSystems."/mnt/animus/media" = {
    device = "10.15.0.2:/mnt/storage/media/media";
    fsType = "nfs4";
    noCheck = true;
    options = [ "x-systemd.after=wireguard-wgautobahn.service" ];
  };
}
