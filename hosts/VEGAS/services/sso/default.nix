{ cluster, config, depot, lib, ... }:
with depot.lib.nginx;
let
  login = "login.${depot.lib.meta.domain}";
  kc = config.links.keycloak;
  patroni = cluster.config.links.patroni-pg-access;
in
{
  links.keycloak.protocol = "http";

  age.secrets.keycloak-dbpass = {
    file = ../../../../secrets/keycloak-dbpass.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
  services.nginx.virtualHosts = { 
    "${login}" = lib.recursiveUpdate (vhosts.proxy kc.url) {
      locations = {
        "= /".return = "302 /auth/realms/master/account/";
        "/".extraConfig = ''
          proxy_busy_buffers_size 512k;
          proxy_buffers 4 512k;
          proxy_buffer_size 256k;
        '';
      };
    };
    "account.${domain}" = vhosts.redirect "https://${login}/auth/realms/master/account/";
  };
  services.keycloak = {
    enable = true;
    package = depot.packages.keycloak;
    database = {
      createLocally = false;
      type = "postgresql";
      host = patroni.ipv4;
      inherit (patroni) port;
      useSSL = false;
      passwordFile = config.age.secrets.keycloak-dbpass.path;
    };
    settings = {
      http-host = kc.ipv4;
      http-port = kc.port;
      hostname = login;
      proxy = "edge";
      # for backcompat, TODO: remove
      http-relative-path = "/auth";
    };
  };
  systemd.services.keycloak.environment = {
    JAVA_OPTS = builtins.concatStringsSep " " [
      "-javaagent:${depot.packages.opentelemetry-java-agent-bin}"
      "-Dotel.resource.attributes=service.name=keycloak"
      "-Dotel.traces.exporter=otlp"
    ];
    OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
    OTEL_EXPORTER_OTLP_ENDPOINT = cluster.config.links.tempo-otlp-grpc.url;
    OTEL_TRACES_SAMPLER = "parentbased_traceidratio";
    OTEL_TRACES_SAMPLER_ARG = "0.50";
  };
}
