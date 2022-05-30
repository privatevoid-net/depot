{ config, lib, tools, ... }:
let
  inherit (tools.meta) domain;
  apiAddr = "api.${domain}";
  proxyTarget = "http://127.0.0.1:${config.portsStr.api}";
  proxy = tools.nginx.vhosts.proxy proxyTarget;
in
{
  # n8n uses "Sustainable Use License"
  nixpkgs.config.allowUnfree = true;

  reservePortsFor = [ "api" ];

  services.n8n = {
    enable = true;
    settings = {
      port = config.ports.api;
    };
  };

  systemd.services.n8n.environment = {
      N8N_LISTEN_ADDRESS = "127.0.0.1";
      N8N_ENDPOINT_WEBHOOK = "api";
      N8N_ENDPOINT_WEBHOOK_TEST = "test";
      WEBHOOK_URL = "https://${apiAddr}";
  };

  services.nginx.virtualHosts."${apiAddr}" = lib.recursiveUpdate proxy {
    locations."/api" = {
      proxyPass = proxyTarget;
      extraConfig = "auth_request off;";
    };
    locations."/test" = {
      proxyPass = proxyTarget;
      extraConfig = "auth_request off;";
    };
  };


  services.oauth2_proxy.nginx.virtualHosts = [ apiAddr ];
}
