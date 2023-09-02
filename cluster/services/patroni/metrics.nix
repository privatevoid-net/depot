{ config, cluster, ... }:

let
  inherit (cluster.config) links vars;

  getMeshIp = name: vars.mesh.${name}.meshIp;
in

{
  age.secrets.postgres-metrics-db-credentials.file = ./passwords/metrics.age;

  services.grafana-agent = {
    settings.integrations.postgres_exporter = {
      enabled = true;
      instance = config.networking.hostName;
      data_source_names = [
        "postgresql://metrics:\${PG_METRICS_DB_PASSWORD}@${getMeshIp config.networking.hostName}:${links.patroni-pg-internal.portStr}/postgres?sslmode=disable"
      ];
      autodiscover_databases = true;
    };
    credentials = {
      PG_METRICS_DB_PASSWORD = config.age.secrets.postgres-metrics-db-credentials.path;
    };
  };
}
