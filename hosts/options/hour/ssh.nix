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
    };

    extraConfig = mkOption {
      description = "Extra SSH client configuration used to connect to this host.";
      type = types.lines;
      default = "";
    };
  };
}
