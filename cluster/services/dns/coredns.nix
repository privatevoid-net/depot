{ config, hosts, inputs, pkgs, tools, ... }:

let
  inherit (hosts.${config.networking.hostName}) interfaces;
  inherit (tools.meta) domain;
  inherit (config.links) localRecursor;
  inherit (inputs.self.packages.${pkgs.system}) stevenblack-hosts;
  dot = config.security.acme.certs."securedns.${domain}";
in

{
  links.localRecursor = {};

  networking.firewall = {
    allowedTCPPorts = [ 853 ];
    allowedUDPPorts = [ 853 ];
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
        bind 127.0.0.1
        hosts ${stevenblack-hosts} {
          fallthrough
        }
        chaos "Private Void DNS" info@privatevoid.net
        forward . ${localRecursor.tuple}
      }
      tls://.:853 {
        bind ${interfaces.primary.addr}
        tls {$CREDENTIALS_DIRECTORY}/dot-cert.pem {$CREDENTIALS_DIRECTORY}/dot-key.pem
        hosts ${stevenblack-hosts} {
          fallthrough
        }
        chaos "Private Void DNS" info@privatevoid.net
        forward . ${localRecursor.tuple}
      }
    '';
  };

  services.pdns-recursor = {
    enable = true;
    dnssecValidation = "process";
    forwardZones = {
      # optimize queries against our own domain
      "${domain}" = interfaces.primary.addr;
    };
    dns = {
      inherit (localRecursor) port;
      address = localRecursor.ipv4;
      allowFrom = [ "127.0.0.1" ];
    };
  };
}
