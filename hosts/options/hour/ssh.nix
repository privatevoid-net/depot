{ lib, ... }:
with lib;

{
  options.ssh = {
    enable = mkEnableOption "Cross-host SSH configuration";

    id = {
      publicKey = mkOption {
        description = "Host SSH public key.";
        type = with types; nullOr str;
        default = null;
      };

      hostNames = mkOption {
        description = "Hostnames through which this host can be reached over SSH.";
        type = with types; listOf str;
        default = [];
      };
    };

    extraConfig = mkOption {
      description = "Extra SSH client configuration used to connect to this host.";
      type = types.lines;
      default = "";
    };
  };
}
