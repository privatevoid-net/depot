{ cluster, config, depot, lib, pkgs, ... }:

let
  inherit (config.reflection) interfaces;
  inherit (depot.lib.meta) domain;
  inherit (config.networking) hostName;

  link = cluster.config.hostLinks.${hostName}.dnsAuthoritative;
  patroni = cluster.config.links.patroni-pg-access;
  inherit (cluster.config.hostLinks.${hostName}) acmeDnsApi;

  otherDnsServers = lib.pipe (cluster.config.services.dns.otherNodes.authoritative hostName) [
    (map (node: cluster.config.hostLinks.${node}.dnsAuthoritative.tuple))
    (lib.concatStringsSep " ")
  ];

  recordsList = lib.mapAttrsToList (lib.const lib.id) cluster.config.dns.records;
  recordsPartitioned = lib.partition (record: record.rewrite.target == null) recordsList;

  staticRecords = let
    escape = type: {
      TXT = builtins.toJSON;
    }.${type} or lib.id;

    recordName = record: {
      "@" = "${record.root}.";
    }.${record.name} or "${record.name}.${record.root}.";
  in lib.flatten (
    map (record: map (target: "${recordName record} ${record.type} ${escape record.type target}") record.target) recordsPartitioned.right
  );

  rewrites = map (record: let
    maybeEscapeRegex = str: if record.rewrite.type == "regex" then "${lib.escapeRegex str}$" else str;
    fqdn = if record.rewrite.type == "exact" && record.name == "@" then "${record.root}."
      else "${record.name}${maybeEscapeRegex ".${record.root}."}";
  in "rewrite stop name ${record.rewrite.type} ${fqdn} ${record.rewrite.target}. answer auto") recordsPartitioned.wrong;

  rewriteConf = pkgs.writeText "coredns-rewrites.conf" ''
    rewrite stop type DS DS
    rewrite stop type NS NS
    rewrite stop type SOA SOA
    rewrite stop type CAA CAA
    rewrite stop type MX MX
    rewrite stop type TXT TXT
    rewrite stop type CNAME CNAME
    ${lib.concatStringsSep "\n" rewrites}
  '';
in {
  links.localAuthoritativeDNS = {};

  age.secrets = {
    acmeDnsDirectKey = {
      file = ./acme-dns-direct-key.age;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  services.acme-dns = {
    enable = true;
    package = depot.packages.acme-dns;
    settings = {
      general = {
        listen = config.links.localAuthoritativeDNS.tuple;
        inherit domain;
        nsadmin = "hostmaster.${domain}";
        nsname = "eu1.ns.${domain}";
        records = staticRecords;
      };
      api = {
        ip = acmeDnsApi.ipv4;
        inherit (acmeDnsApi) port;
      };
      database = {
        engine = "postgres";
        connection = "postgres://acmedns@${patroni.tuple}/acmedns?sslmode=disable";
      };
    };
  };

  services.locksmith.waitForSecrets.acme-dns = [
    "patroni-acmedns"
  ];

  systemd.services.acme-dns.serviceConfig.EnvironmentFile = with config.age.secrets; [
    "/run/locksmith/patroni-acmedns"
    acmeDnsDirectKey.path
  ];

  services.coredns = {
    enable = true;
    config = ''
      .:${link.portStr} {
        bind ${interfaces.primary.addr}
        chaos "Private Void DNS" info@privatevoid.net
        cache {
          success 4000 86400
          disable denial
          prefetch 3
          serve_stale 86400s verify
        }
        template ANY DS {
          rcode NXDOMAIN
        }
        forward service.eu-central.sd-magic.${domain} 127.0.0.1:8600
        forward addr.eu-central.sd-magic.${domain} 127.0.0.1:8600
        import ${rewriteConf}
        forward . ${config.links.localAuthoritativeDNS.tuple} ${otherDnsServers} {
          policy sequential
        }
      }
    '';
  };

  systemd.services.coredns = {
    after = [ "acme-dns.service" ];
    serviceConfig = {
      MemoryMax = "200M";
      MemorySwapMax = "50M";
      CPUQuota = "25%";
    };
  };

  consul.services = {
    authoritative-dns = {
      unit = "acme-dns";
      definition = {
        name = "authoritative-dns-backend";
        address = config.links.localAuthoritativeDNS.ipv4;
        port = config.links.localAuthoritativeDNS.port;
        checks = lib.singleton {
          interval = "60s";
          tcp = config.links.localAuthoritativeDNS.tuple;
        };
      };
    };
    acme-dns.definition = {
      name = "acme-dns";
      address = acmeDnsApi.ipv4;
      port = acmeDnsApi.port;
      checks = lib.singleton {
        interval = "60s";
        http = "${acmeDnsApi.url}/health";
      };
    };
  };
}
