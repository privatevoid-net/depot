{ config, hosts, inputs, pkgs, tools, ... }:
# TODO: is this secure?
let
  inherit (hosts.${config.networking.hostName}) interfaces;
  inherit (tools.meta) domain;
  dot = config.security.acme.certs."securedns.${domain}";
in {
  imports = [ ./zones.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 53 853 ];
    allowedUDPPorts = [ 53 853 ];
  };

  systemd.services.coredns = {
    after = [ "network-addresses-vstub.service" ];
    serviceConfig.LoadCredential = [
      "dot-cert.pem:${dot.directory}/fullchain.pem"
      "dot-key.pem:${dot.directory}/key.pem"
    ];
  };
  security.acme.certs."securedns.${domain}" = {
    group = "nginx";
    webroot = "/var/lib/acme/acme-challenge";
    # using a different ACME provider because Android Private DNS is fucky
    server = "https://api.buypass.com/acme/directory";
    reloadServices = [
      "coredns.service"
    ];
  };
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
      tls://.:853 {
        bind ${interfaces.primary.addr}
        tls {$CREDENTIALS_DIRECTORY}/dot-cert.pem {$CREDENTIALS_DIRECTORY}/dot-key.pem
        hosts ${inputs.self.packages.${pkgs.system}.stevenblack-hosts} {
          fallthrough
        }
        chaos "Private Void DNS" info@privatevoid.net
        forward . ${interfaces.primary.addr}
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
        ${interfaces.vstub.addr}/32;
        10.100.0.0/16;
        10.10.0.0/16;
      };
      acl "publicservers" {
        116.202.226.86/32;
      };
    '';
    extraOptions = ''
      recursion yes;
      allow-recursion { trusted; ${interfaces.primary.addr}/32; };
      dnssec-validation no;
    '';
  };
}
