{ cluster, lib, ... }:
let
  myNode = cluster.config.vars.mesh.${cluster.config.vars.hostName};

  relabel = from: to: {
    source_labels = [ from ];
    target_label = to;
  };
in {
  services.journald.extraConfig = "Storage=volatile";

  services.grafana-agent = {
    enable = true;
    settings = {
      metrics.global.remote_write = lib.singleton {
        url = "${cluster.config.links.prometheus-ingest.url}/api/v1/write";
      };
      integrations.node_exporter = {
        enabled = true;
        instance = cluster.config.vars.hostName;
        enable_collectors = [
          "systemd"
        ];
      };
      logs.configs = lib.singleton {
        name = "logging";
        positions.filename = "\${STATE_DIRECTORY:/tmp}/logging-positions.yaml";
        clients = [
          { url = "${cluster.config.links.loki-ingest.url}/loki/api/v1/push"; }
        ];
        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels.host = cluster.config.vars.hostName;
            };
              relabel_configs = [
                (relabel "__journal__systemd_unit" "systemd_unit")
                (relabel "__journal__hostname" "machine_name")
                (relabel "__journal__exe" "executable")
                (relabel "__journal__comm" "command")
                (relabel "__journal__boot_id" "systemd_boot_id")
                (relabel "__journal__systemd_cgroup" "systemd_cgroup")
                (relabel "__journal_syslog_identifier" "syslog_identifier")
              ];
          }
        ];
      };
    };
  };
}
