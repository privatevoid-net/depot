{ lib, ... }:

with lib;

{
  options.services.alloy = {
    metrics = {
      receiver.url = mkOption {
        type = types.str;
      };
      targets = mkOption {
        type = types.attrsOf (types.submodule ({ name, ... }: {
          options = {
            name = mkOption {
              type = types.str;
              default = name;
            };
            address = mkOption {
              type = types.str;
            };
            labels = mkOption {
              type = types.attrsOf types.str;
              default = {};
            };
            scrapeInterval = mkOption {
              description = "Scrape interval in seconds.";
              type = types.ints.unsigned;
              default = 5;
            };
            scrapeTimeout = mkOption {
              description = "Scrape timeout in seconds.";
              type = types.ints.unsigned;
              default = 5;
            };
            metricsPath = mkOption {
              type = types.str;
              default = "/metrics";
            };
          };
        }));
        default = {};
      };
      integrations = mkOption {
        type = types.attrsOf (types.submodule ({ name, ... }: {
          options = {
            name = mkOption {
              type = types.str;
              default = name;
            };
            exporter = mkOption {
              type = types.str;
            };
            labels = mkOption {
              type = types.attrsOf types.str;
              default = {};
            };
            settings = mkOption {
              type = types.attrs;
              default = {};
            };
            configText = mkOption {
              type = types.lines;
              default = "";
            };
            relabelConfigText = mkOption {
              type = types.nullOr types.lines;
              default = null;
            };
            scrapeInterval = mkOption {
              description = "Scrape interval in seconds.";
              type = types.ints.unsigned;
              default = 5;
            };
            scrapeTimeout = mkOption {
              description = "Scrape timeout in seconds.";
              type = types.ints.unsigned;
              default = 5;
            };
          };
        }));
        default = {};
      };
    };
  };
}
