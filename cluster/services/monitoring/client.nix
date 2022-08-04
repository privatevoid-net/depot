{ cluster, config, lib, pkgs, ... }:
let
  myNode = cluster.config.vars.mesh.${cluster.config.vars.hostName};

  writeJSON = filename: data: pkgs.writeText filename (builtins.toJSON data);

  relabel = from: to: {
    source_labels = [ from ];
    target_label = to;
  };

  hasJitsi = lib.mkIf config.services.jitsi-meet.enable;
in {
  services.journald.extraConfig = "Storage=volatile";

  services.prometheus.exporters = {
    node = {
      enable = true;
      listenAddress = myNode.meshIp;
    };

    jitsi = hasJitsi {
      enable = true;
      listenAddress = myNode.meshIp;
      interval = "60s";
    };
  };

  systemd.services.prometheus-node-exporter = {
    after = [ "wireguard-wgmesh.service" ];
    serviceConfig.RestartSec = "10s";
  };
  systemd.services.prometheus-jitsi-exporter = hasJitsi {
    after = [ "wireguard-wgmesh.service" ];
    serviceConfig.RestartSec = "10s";
  };

  systemd.services.promtail = {
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.grafana-loki}/bin/promtail --config.expand-env=true --config.file ${writeJSON "promtail.yaml" {
        server.disable = true;
        positions.filename = "\${STATE_DIRECTORY:/tmp}/promtail-positions.yaml";
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
      }}";
      StateDirectory = "promtail";
    };
  };
}
