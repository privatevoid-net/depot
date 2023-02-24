{ lib, ... }:
with lib;

{
  options.hyprspace = {
    enable = mkEnableOption "Cross-host Hyprspace configuration";

    id = mkOption {
      description = "Hyprspace PeerID.";
      type = types.str;
    };

    addr = mkOption {
      description = "Hyprspace internal IP address.";
      type = types.str;
    };

    routes = mkOption {
      description = "Networks to export to Hyprspace.";
      type = with types; listOf str;
      default = [];
    };

    listenPort = mkOption {
      description = "The port the Hyprspace daemon should listen on.";
      type = types.port;
      default = 8001;
    };
  };
}
