{ config, hosts, inputs, pkgs, ... }:
# TODO: is this secure?
let
  inherit (hosts.${config.networking.hostName}) interfaces;
in {
  imports = [ ./zones.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  systemd.services.coredns.after = [ "network-addresses-vstub.service" ];
  services.coredns = {
    enable = true;
    config = ''
      . {
        bind ${interfaces.vstub.addr}
        hosts ${inputs.self.packages.${pkgs.system}.stevenblack-hosts} {
          fallthrough
        }
        chaos "Private Void DNS" info@privatevoid.net
        forward . 127.0.0.1
      }
    '';
  };

  services.bind = {
    enable = true;
    # TODO: un-hardcode all ip addresses
    listenOn = [ interfaces.primary.addr "127.0.0.1" ];
    ipv4Only = true;

    cacheNetworks = [ "10.0.0.0/8" ];
    extraConfig = ''
      acl "trusted" {
        127.0.0.0/8;
        ::1/128;
        ${interfaces.primary.addr}/32;
        ${interfaces.vstub.addr}/32;
        10.100.0.0/16;
        10.10.0.0/16;
      };
      acl "publicservers" {
        ${interfaces.primary.addr}/32;
        116.202.226.86/32;
      };
    '';
    extraOptions = ''
      recursion yes;
      allow-recursion { trusted; };
      dnssec-validation no;
    '';
  };
}
