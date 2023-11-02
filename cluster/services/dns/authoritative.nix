{ cluster, config, depot, lib, pkgs, ... }:

let
  inherit (depot.reflection) interfaces;
  inherit (depot.lib.meta) domain;
  inherit (config.networking) hostName;

  link = cluster.config.hostLinks.${hostName}.dnsAuthoritative;
  patroni = cluster.config.links.patroni-pg-access;

  otherDnsServers = lib.pipe (with cluster.config.services.dns.otherNodes; (master hostName) ++ (slave hostName)) [
    (map (node: cluster.config.hostLinks.${node}.dnsAuthoritative.tuple))
    (lib.concatStringsSep " ")
  ];

  translateConfig = cfg: let
    configList = lib.mapAttrsToList (n: v: "${n}=${v}") cfg;
  in lib.concatStringsSep "\n" configList;

  rewriteRecords = lib.filterAttrs (_: record: record.rewriteTarget != null) cluster.config.dns.records;

  rewrites = lib.mapAttrsToList (_: record: "rewrite stop name exact ${record.name}.${record.root}. ${record.rewriteTarget}.") rewriteRecords;

  rewriteConf = pkgs.writeText "coredns-rewrites.conf" (lib.concatStringsSep "\n" rewrites);
in {
  links.localAuthoritativeDNS = {};

  age.secrets = {
    pdns-db-credentials = {
      file = ./pdns-db-credentials.age;
      mode = "0400";
      owner = "pdns";
      group = "pdns";
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  services.powerdns = {
    enable = true;
    extraConfig = translateConfig {
      launch = "gpgsql";
      local-address = config.links.localAuthoritativeDNS.tuple;
      gpgsql-host = patroni.ipv4;
      gpgsql-port = patroni.portStr;
      gpgsql-dbname = "powerdns";
      gpgsql-user = "powerdns";
      gpgsql-extra-connection-parameters = "passfile=${config.age.secrets.pdns-db-credentials.path}";
      version-string = "Private Void DNS";
      enable-lua-records = "yes";
      expand-alias = "yes";
      resolver = "127.0.0.1:8600";
    };
  };

  services.coredns = {
    enable = true;
    config = ''
      .:${link.portStr} {
        bind ${interfaces.primary.addr}
        chaos "Private Void DNS" info@privatevoid.net
        cache {
          success 4000 86400
          denial 0
          prefetch 3
          serve_stale 86400s
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
    after = [ "pdns.service" ];
  };

  consul.services.pdns = {
    mode = "external";
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
}
