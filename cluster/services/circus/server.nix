{ cluster, config, depot, depot', ... }:

let
  inherit (cluster.config.services.circus) secrets;
  link = cluster.config.hostLinks.${config.networking.hostName}.circusServer;
in

{
  imports = [
    depot.inputs.circus.nixosModules.default
    ./projects.nix
  ];

  security.acme.certs."circus-agent-rpc.manic.systems" = {
    dnsProvider = "exec";
    group = "circus";
    reloadServices = [
      "circus-queue-runner.service"
    ];
  };

  services.circus = {
    enable = true;
    package = depot'.inputs.circus.packages.circus-server;
    evaluatorPackage = depot'.inputs.circus.packages.circus-evaluator;
    queueRunnerPackage = depot'.inputs.circus.packages.circus-queue-runner;
    migratePackage = depot'.inputs.circus.packages.circus-migrate-cli;
    server.enable = true;
    evaluator.enable = true;
    queueRunner.enable = true;
    settings = {
      server = {
        host = link.ipv4;
        inherit (link) port;
      };
      database.url = "postgresql:///circus?host=/run/postgresql";
      evaluator = {
        poll_interval = 600;
      };
      cache = {
        secret_key_file = secrets.cacheKey.path;
        public_url = "https://ci.manic.systems/nix-cache";
      };
      signing = {
        enabled = true;
        # pubkey: cache.manic.systems-1:s6OZanN8Us8vRi0jVivP3qlMn0cYHBjBALKrNe5nH8s=
        key_file = secrets.s3CacheKey.path;
      };
      queue_runner = {
        poll_interval = 30;
        rpc = {
          bind = "0.0.0.0:8443";
          auth_tokens = [
            "ed611f88c7fb27103afba7ddad8733adf06f56e8837eba505c96349ef5fbfd8c"
            "d74548cafebeec602bd92a0bae0822ffecefd95fcf04b51c387af19ff043d356"
            "ce588d1fb6eae218f664b2275f3bd573bafca69847e77ff2a090ef1850aa6608"
          ];
          max_connections = 128;
          heartbeat_ttl_secs = 60;
          tls = {
            cert_file = "${config.security.acme.certs."circus-agent-rpc.manic.systems".directory}/fullchain.pem";
            key_file = "${config.security.acme.certs."circus-agent-rpc.manic.systems".directory}/key.pem";
          };
          cache_substituter = "https://ci.manic.systems/nix-cache";
          cache_public_key = "ci.manic.systems-1:5EoSMEa0D55JxnmC0yr2L7/2eHr/nHH0XWupc+Z9z88=";
        };
      };
      cache_upload = {
        enabled = true;
        store_uri = "s3://circus-cache-ndkyblidbo7zphxq38qq169tvs6ifjkg?region=fsn1&endpoint=https://fsn1.your-objectstorage.com";
        s3 = {
          region = "fsn1";
          endpoint_url = "https://fsn1.your-objectstorage.com";
        };
      };
    };
  };

  systemd.services = {
    circus-queue-runner.serviceConfig.EnvironmentFile = [
      secrets.s3Credentials.path
    ];
  };

  networking.firewall.allowedTCPPorts = [
    8443
  ];
}
