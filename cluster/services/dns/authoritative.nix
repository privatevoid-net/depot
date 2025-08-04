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

  toList = lib.mapAttrsToList (lib.const lib.id);

  zoneRecordsByType = lib.mapAttrs (_: zone: let
    partitioned = lib.partition (record: record.rewrite.target == null) (toList zone.records);
  in {
    static = partitioned.right;
    rewrite = partitioned.wrong;
  }) cluster.config.dns.zones;

  escapeRecordContent = type: {
    TXT = builtins.toJSON;
  }.${type} or lib.id;

  rewrites = let
    allRewriteRecords = lib.pipe zoneRecordsByType [
      (lib.mapAttrs (_: records: records.rewrite))
      lib.attrValues
      lib.flatten
    ];
  in map (record: let
    maybeEscapeRegex = str: if record.rewrite.type == "regex" then "${lib.escapeRegex str}$" else str;
    fqdn = if record.rewrite.type == "exact" && record.name == "@" then "${record.root}."
      else "${record.name}${maybeEscapeRegex ".${record.root}."}";
  in "rewrite stop name ${record.rewrite.type} ${fqdn} ${record.rewrite.target}. answer auto") allRewriteRecords;

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

  mkZoneRecords = { name, ttl, type, target, ... }: lib.concatStringsSep "\n" (map
    (targetInstance: "${name} ${toString ttl} IN ${type} ${escapeRecordContent type targetInstance}")
  target);

  mkZoneFile = zoneDomain: records: pkgs.writeText "${zoneDomain}.zone" ''
    $ORIGIN ${zoneDomain}.
    @ 3600 IN SOA eu1.ns.${domain}. hostmaster.${domain}. 2025010100 28800 7200 604800 86400

    ${lib.concatStringsSep "\n" (
      map mkZoneRecords records
    )}
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
        records = [];
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
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: records: ''
            file ${mkZoneFile name records.static} ${name} {
              reload 0
              fallthrough
            }
          '') zoneRecordsByType
        )}
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
