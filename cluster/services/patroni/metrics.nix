{ config, cluster, ... }:

let
  inherit (cluster.config) links vars;
  inherit (cluster.config.services.patroni) secrets;

  getMeshIp = name: vars.mesh.${name}.meshIp;
in

{
  systemd.services.alloy.serviceConfig.EnvironmentFile = [ secrets.metricsCredentials.path ];

  services.alloy.metrics.integrations.postgres_exporter = {
    exporter = "postgres";
    labels.instance = config.networking.hostName;
    configText = ''
      data_source_names = [
        string.format("postgresql://metrics:%s@${getMeshIp config.networking.hostName}:${links.patroni-pg-internal.portStr}/postgres?sslmode=disable",sys.env("PG_METRICS_DB_PASSWORD")),
      ]
      autodiscovery {
        enabled = true
      }
    '';
  };
}
