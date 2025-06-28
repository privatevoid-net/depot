{ cluster, config, depot, lib, ... }:

let
  inherit (config.reflection) interfaces;
  inherit (depot.lib.meta) domain;
  inherit (config.networking) hostName;

  link = cluster.config.hostLinks.${hostName}.dnsResolver;
  backend = cluster.config.hostLinks.${hostName}.dnsResolverBackend;

  otherRecursors = lib.pipe (cluster.config.services.dns.otherNodes.coredns hostName) [
    (map (node: cluster.config.hostLinks.${node}.dnsResolverBackend.tuple))
    (lib.concatStringsSep " ")
  ];

  authoritativeServers = map
    (node: cluster.config.hostLinks.${node}.dnsAuthoritative.tuple)
    cluster.config.services.dns.nodes.authoritative;

  inherit (depot.packages) stevenblack-hosts;
  dot = config.security.acme.certs."securedns.${domain}";
in

{
  links.localRecursor = {};

  networking.firewall = {
    allowedTCPPorts = [ 853 ];
    allowedUDPPorts = [ 853 ];
  };

  systemd.services.coredns = {
    after = (lib.optional (interfaces ? vstub) "network-addresses-vstub.service") ++ [
      "acme-selfsigned-securedns.${domain}.service"
    ];
    before = [ "acme-securedns.${domain}.service" ];
    wants = [ "acme-finished-securedns.${domain}.target" ];
    serviceConfig = {
      LoadCredential = [
        "dot-cert.pem:${dot.directory}/fullchain.pem"
        "dot-key.pem:${dot.directory}/key.pem"
      ];
      ExecReload = lib.mkForce [];
    };
  };

  security.acme.certs."securedns.${domain}" = {
    dnsProvider = "exec";
    # using a different ACME provider because Android Private DNS is fucky
    server = "https://api.buypass.com/acme/directory";
    reloadServices = [
      "coredns.service"
    ];
  };

  services.coredns = {
    enable = true;
    config = ''
      (localresolver) {
        hosts ${stevenblack-hosts} {
          fallthrough
        }
        chaos "Private Void DNS" info@privatevoid.net
        forward hyprspace. 127.43.104.80:11355
        forward ${domain}. ${lib.concatStringsSep " " authoritativeServers} {
          policy random
        }
        forward . ${backend.tuple} ${otherRecursors} {
          policy sequential
        }
      }
      .:${link.portStr} {
        ${lib.optionalString (interfaces ? vstub) "bind ${interfaces.vstub.addr}"}
        bind 127.0.0.1
        bind ${link.ipv4}
        import localresolver
      }
      tls://.:853 {
        bind ${interfaces.primary.addr}
        tls {$CREDENTIALS_DIRECTORY}/dot-cert.pem {$CREDENTIALS_DIRECTORY}/dot-key.pem
        import localresolver
      }
    '';
  };

  services.pdns-recursor = {
    enable = true;
    dnssecValidation = "process";
    dns = {
      inherit (backend) port;
      address = [ backend.ipv4 ];
      allowFrom = [ "127.0.0.1" cluster.config.vars.meshNet.cidr "10.100.3.0/24" ];
    };

    # ew
    yaml-settings = {
      recursor = {
        forward_zones = [
          {
            zone = domain;
            forwarders = authoritativeServers;
          }
        ];
      };
    };
  };

  consul.services.securedns = {
    unit = "coredns";
    mode = "external";
    definition = rec {
      name = "securedns";
      address = interfaces.primary.addrPublic;
      port = 853;
      checks = lib.singleton {
        name = "SecureDNS";
        tcp = "${address}:${toString port}";
        interval = "30s";
      };
    };
  };
}
