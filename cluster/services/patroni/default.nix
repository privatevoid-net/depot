{ config, ... }:

{
  imports = [
    ./options.nix
    ./incandescence.nix
    ./simulacrum/test-data.nix
  ];

  links = {
    patroni-pg-internal.ipv4 = "0.0.0.0";
    patroni-api.ipv4 = "0.0.0.0";
    patroni-pg-access.ipv4 = "127.0.0.1";
  };
  services.patroni = {
    nodes = {
      worker = [ "grail" "VEGAS" ];
      haproxy = [ "checkmate" "grail" "VEGAS" "prophet" ];
    };
    nixos = {
      worker = [
        ./worker.nix
        ./metrics.nix
        ./create-databases.nix
      ];
      haproxy = ./haproxy.nix;
    };
    secrets = let
      inherit (config.services.patroni) nodes;
      default = {
        nodes = nodes.worker;
        owner = "patroni";
      };
    in {
      PATRONI_REPLICATION_PASSWORD = default;
      PATRONI_SUPERUSER_PASSWORD = default;
      PATRONI_REWIND_PASSWORD = default;
      metricsCredentials.nodes = nodes.worker;
    };
    simulacrum = {
      enable = true;
      deps = [ "consul" "incandescence" "locksmith" ];
      settings = ./simulacrum/test.nix;
    };
  };
}
