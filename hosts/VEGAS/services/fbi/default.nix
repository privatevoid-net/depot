{ config, lib, tools, ... }:
with tools.nginx;
{
  services = {
    radarr = {
      enable = true;
    };
    sonarr = {
      enable = true;
    };
    ombi = {
      enable = true;
      port = 35000;
    };

    nginx.virtualHosts = mappers.mapSubdomains {
      radarr = vhosts.proxy "http://127.0.0.1:7878";
      sonarr = vhosts.proxy "http://127.0.0.1:8989";
      fbi-requests = vhosts.proxy "http://127.0.0.1:${builtins.toString config.services.ombi.port}";
    };
  };
  systemd.services.radarr.serviceConfig.Slice = "mediamanagement.slice";
  systemd.services.sonarr.serviceConfig.Slice = "mediamanagement.slice";
}
