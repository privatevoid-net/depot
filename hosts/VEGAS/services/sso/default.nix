{ config, inputs, lib, pkgs, tools, ... }:
with tools.nginx;
let
  login = "login.${tools.meta.domain}";
  cfg = config.services.keycloak;
  kc = config.links.keycloak;
in
{
  tested.requiredChecks = [ "keycloak" ];
  links.keycloak.protocol = "http";

  imports = [
    ./identity-management.nix
  ];
  age.secrets.keycloak-dbpass = {
    file = ../../../../secrets/keycloak-dbpass.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
  services.nginx.virtualHosts = { 
    "${login}" = lib.recursiveUpdate (vhosts.proxy kc.url) {
      locations."= /".return = "302 /auth/realms/master/account/";
    };
    "account.${domain}" = vhosts.redirect "https://${login}/auth/realms/master/account/";
  };
  services.keycloak = {
    enable = true;
    database = {
      createLocally = true;
      type = "postgresql";
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
      "-javaagent:${inputs.self.packages.${pkgs.system}.opentelemetry-java-agent-bin}"
      "-Dotel.resource.attributes=service.name=keycloak"
      "-Dotel.traces.exporter=otlp"
    ];
    OTEL_EXPORTER_OTLP_PROTOCOL = "grpc";
    OTEL_EXPORTER_OTLP_ENDPOINT = config.links.tempo-otlp-grpc.url;
    OTEL_TRACES_SAMPLER = "parentbased_traceidratio";
    OTEL_TRACES_SAMPLER_ARG = "0.01";
  };
}
