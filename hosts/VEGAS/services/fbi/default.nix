{ config, lib, tools, ... }:
with tools.nginx;
{
  reservePortsFor = [ "ombi" ];

  services = {
    radarr = {
      enable = true;
    };
    sonarr = {
      enable = true;
    };
    prowlarr = {
      enable = true;
    };
    ombi = {
      enable = true;
      port = config.ports.ombi;
    };

    nginx.virtualHosts = mappers.mapSubdomains {
      radarr = vhosts.proxy "http://127.0.0.1:7878";
      sonarr = vhosts.proxy "http://127.0.0.1:8989";
      fbi-index = vhosts.proxy "http://127.0.0.1:9696";
      fbi-requests = vhosts.proxy "http://127.0.0.1:${config.portsStr.ombi}";
    };
  };
  systemd.services.radarr.serviceConfig.Slice = "mediamanagement.slice";
  systemd.services.sonarr.serviceConfig.Slice = "mediamanagement.slice";
  systemd.services.prowlarr = {
    after = [ "wireguard-wgmv-es7.service" "network-addresses-wgmv-es7.service" ];
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
