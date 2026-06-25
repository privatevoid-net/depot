{ config, inputs, pkgs, ... }:

{
  networking.networkmanager = {
    dns = "systemd-resolved";
    settings.connectivity = {
      url = "http://whoami.privatevoid.net/online";
      response = "CONNECTED_GLOBAL";
      interval = 120;
    };
  };
  services.resolved = {
    enable = true;
    settings.Resolve = let
      dnsServers = [
        "95.216.8.12#securedns.privatevoid.net"
        "152.67.73.164#securedns.privatevoid.net"
      ];
    in {
      Cache = "no-negative";
      DNS = dnsServers;
      DNSOverTLS = "opportunistic";
      DNSSEC = "false";
      FallbackDNS = dnsServers;
      LLMNR = "true";
    };
  };
  networking.firewall = let
    ports = [
      5353
      5355
    ];
  in {
    allowedTCPPorts = ports;
    allowedUDPPorts = ports;
  };
}
