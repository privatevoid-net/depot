{ cluster, config, hosts, inputs, lib, pkgs, tools, ... }:

let
  inherit (hosts.${config.networking.hostName}) interfaces;
  inherit (cluster.config) vars;

  patroni = cluster.config.links.patroni-pg-access;
  pdns-api = cluster.config.links.powerdns-api;

  translateConfig = cfg: let
    configList = lib.mapAttrsToList (n: v: "${n}=${v}") cfg;
  in lib.concatStringsSep "\n" configList;
in {
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
      local-address = interfaces.primary.addr;
      gpgsql-host = patroni.ipv4;
      gpgsql-port = patroni.portStr;
      gpgsql-dbname = "powerdns";
      gpgsql-user = "powerdns";
      gpgsql-extra-connection-parameters = "passfile=${config.age.secrets.pdns-db-credentials.path}";
      version-string = "Private Void DNS";
    };
  };
}
