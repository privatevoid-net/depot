{ cluster, config, depot, lib, pkgs, ... }:
let
  cfg = config.services.alloy;

  toAlloyValue = value: let
    encodedStr = builtins.toJSON value;
  in if builtins.isString value then encodedStr else "encoding.from_json(${builtins.toJSON encodedStr})";

  toAlloyBlocks = attrs: f: lib.pipe attrs [
    (lib.mapAttrsToList f)
    (lib.concatStringsSep "\n\n")
  ];
in {
  imports = [
    ./options/alloy.nix
  ];

  links.alloy.protocol = "http";

  services.journald.extraConfig = "Storage=volatile";

  services.alloy = {
    enable = true;
    package = depot.packages.grafana-alloy;
    metrics = {
      receiver.url = "${cluster.config.links.prometheus-ingest.url}/api/v1/write";
      integrations = {
        agent.exporter = "self";
        node_exporter = {
          exporter = "unix";
          labels.instance = config.networking.hostName;
          settings.enable_collectors = [ "systemd" ];
        };
      };
    };
    extraFlags = [
      "--disable-reporting" # fuck you grafana
      "--server.http.listen-addr=${config.links.alloy.tuple}"
    ];
    configPath = pkgs.writeText "config.alloy" ''
      prometheus.remote_write "default" {
        endpoint {
          name = "metrics"
          url = ${toAlloyValue cfg.metrics.receiver.url}
        }
      }

      ${toAlloyBlocks cfg.metrics.targets (name: value: let
          targetId = builtins.hashString "sha256" name;
        in ''
          // Target: ${name} (${value.name})
          prometheus.scrape "metrics_${targetId}" {
            targets = ${toAlloyValue [(value.labels // { __address__ = value.address; })]}
            forward_to = [prometheus.remote_write.default.receiver]
            job_name = ${toAlloyValue value.name}
            scrape_interval = ${toAlloyValue "${toString value.scrapeInterval}s"}
            scrape_timeout = ${toAlloyValue "${toString value.scrapeTimeout}s"}
            metrics_path = ${toAlloyValue value.metricsPath}
          }
      '')}

      ${toAlloyBlocks cfg.metrics.integrations (name: value: let
          targetId = builtins.hashString "sha256" name;
          allLabels = value.labels // {
            job = "integrations/${value.name}";
          };
        in ''
          // Integration: ${name} (${value.name})
          prometheus.exporter.${value.exporter} "integrations_${targetId}" {
            ${toAlloyBlocks value.settings (settingName: settingValue: ''
              ${settingName} = ${toAlloyValue settingValue}
            '')}
            ${value.configText}
          }

          discovery.relabel "integrations_${targetId}" {
            targets = prometheus.exporter.${value.exporter}.integrations_${targetId}.targets
            ${if value.relabelConfigText == null then toAlloyBlocks allLabels (labelName: labelValue: ''
                rule {
                  target_label = ${toAlloyValue labelName}
                  replacement = ${toAlloyValue labelValue}
                }
            '') else value.relabelConfigText}
          }

          prometheus.scrape "integrations_${targetId}" {
            targets = discovery.relabel.integrations_${targetId}.output
            forward_to = [prometheus.remote_write.default.receiver]
            job_name = ${toAlloyValue allLabels.job}
            scrape_interval = ${toAlloyValue "${toString value.scrapeInterval}s"}
            scrape_timeout = ${toAlloyValue "${toString value.scrapeTimeout}s"}
          }
      '')}

      loki.relabel "journal" {
        forward_to = []
        ${let
          relabels = {
            __journal__systemd_unit = "systemd_unit";
            __journal__hostname = "machine_name";
            __journal__exe = "executable";
            __journal__comm = "command";
            __journal__boot_id = "systemd_boot_id";
            __journal__systemd_cgroup = "systemd_cgroup";
            __journal_syslog_identifier = "syslog_identifier";
          };
        in toAlloyBlocks relabels (from: to: ''
          rule {
            source_labels = [${toAlloyValue from}]
            target_label = ${toAlloyValue to}
          }
        '')}
      }

      loki.source.journal "journal" {
        forward_to = [loki.write.logging.receiver]
        relabel_rules = loki.relabel.journal.rules
        labels = ${toAlloyValue { host = config.networking.hostName; }}
        max_age = "12h"
      }

      loki.write "logging" {
        endpoint {
          url = "${cluster.config.ways.ingest-logs.url}/loki/api/v1/push"
        }
      }
    '';
  };
}
