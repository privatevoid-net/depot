{ config, lib, ... }:

{
  vars.patroni = {
    passwords = {
      PATRONI_REPLICATION_PASSWORD = ./passwords/replication.age;
      PATRONI_SUPERUSER_PASSWORD = ./passwords/superuser.age;
      PATRONI_REWIND_PASSWORD = ./passwords/rewind.age;
    };
  };
  links = {
    patroni-pg-internal.ipv4 = "0.0.0.0";
    patroni-api.ipv4 = "0.0.0.0";
    patroni-pg-access.ipv4 = "127.0.0.1";
  };
  services.patroni = {
    nodes = {
      worker = [ "thunderskin" "VEGAS" "prophet" ];
      haproxy = [ "checkmate" "VEGAS" "prophet" ];
    };
    nixos = {
      worker = ./worker.nix;
      haproxy = ./haproxy.nix;
    };
  };
}
