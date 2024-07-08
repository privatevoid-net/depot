{ config, cluster, ... }:

let
  inherit (cluster.config) links vars;
  inherit (cluster.config.services.patroni) secrets;

  getMeshIp = name: vars.mesh.${name}.meshIp;
in

{
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
      PG_METRICS_DB_PASSWORD = secrets.metricsCredentials.path;
    };
  };
}
