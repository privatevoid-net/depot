{ lib, pkgs, tools, ... }:
let
  inherit (tools.nginx) domain vhosts;
in
{
  services.nginx.virtualHosts."chat.${domain}" = vhosts.static (pkgs.element-web.override {
    conf = {
      default_server_config."m.homeserver" = {
        base_url = "https://matrix.${domain}:443";
        server_name = tools.meta.domain;
      };
      disable_3pid_login = true;
      disable_custom_urls = true;

      brand = "Private Void Chat";
      # TODO: integrations
      enableLabs = true;
      showLabsSettings = true;
      features = with lib; flip genAttrs (_: "labs") [
        "feature_custom_status"
        "feature_custom_tags"
        "feature_many_integration_managers"
        "feature_new_spinner"
        "feature_pinning"
        "feature_state_counters"
      ];
      default_federate = true;
      default_theme = "dark";
      roomDirectory.servers = [ domain "matrix.org" ];
      piwik = false;
      jitsi.preferredDomain = "meet.${domain}";
    };
  });
}
