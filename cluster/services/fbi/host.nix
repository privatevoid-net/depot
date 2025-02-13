{ config, depot, ... }:
with depot.lib.nginx;
{
  links = {
    ombi.protocol = "http";
    radarr = {
      protocol = "http";
      port = 7878;
    };
    sonarr = {
      protocol = "http";
      port = 8989;
    };
    prowlarr = {
      protocol = "http";
      port = 9696;
    };
  };

  users = {
    groups.mediamanagers.gid = 646000020;
    users = {
      radarr.extraGroups = [ "mediamanagers" ];
      sonarr.extraGroups = [ "mediamanagers" ];
    };
  };
  services = {
    radarr = {
      enable = true;
    };
    sonarr = {
      enable = true;
      package = depot.packages.sonarr5;
    };
    prowlarr = {
      enable = true;
    };
    ombi = {
      enable = true;
      inherit (config.links.ombi) port;
    };

    nginx.virtualHosts = with config.links; mappers.mapSubdomains {
      radarr = vhosts.proxy radarr.url;
      sonarr = vhosts.proxy sonarr.url;
      fbi-index = vhosts.proxy prowlarr.url;
      fbi-requests = vhosts.proxy ombi.url;
    };
  };
  systemd.services.radarr.serviceConfig.Slice = "mediamanagement.slice";
  systemd.services.sonarr.serviceConfig.Slice = "mediamanagement.slice";
  systemd.services.prowlarr = {
    after = [ "tor.service" ];
    serviceConfig = {
      Slice = "mediamanagement.slice";
      IPAddressDeny = [ "any" ];
      IPAddressAllow = [
        "localhost"
        "10.100.0.0/24"
      ];
    };
  };
}
