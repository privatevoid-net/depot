{ config, lib, tools, ... }:
with tools.nginx;
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

  services = {
    radarr = {
      enable = true;
      user = "svcradarr";
    };
    sonarr = {
      enable = true;
      user = "svcsonarr";
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
  systemd.slices.mediamanagement.after = [ "nss-user-lookup.target" ];
  systemd.services.radarr.serviceConfig.Slice = "mediamanagement.slice";
  systemd.services.sonarr.serviceConfig.Slice = "mediamanagement.slice";
  systemd.services.prowlarr = {
    after = [ "wireguard-wgmv-es1.service" "network-addresses-wgmv-es1.service" ];
    serviceConfig = {
      Slice = "mediamanagement.slice";
      IPAddressDeny = [ "any" ];
      IPAddressAllow = [
        "localhost"
        "10.64.0.0/16"
        "10.124.0.0/16"
        "10.100.0.0/24"
      ];
    };
  };
}
