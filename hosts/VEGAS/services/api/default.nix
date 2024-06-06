{ config, lib, depot, ... }:
let
  inherit (depot.lib.meta) domain;
  apiAddr = "api.${domain}";
  proxyTarget = config.links.api.url;
  proxy = depot.lib.nginx.vhosts.proxy proxyTarget;
in
{
  # n8n uses "Sustainable Use License"
  nixpkgs.config.allowUnfree = true;

  links.api.protocol = "http";

  services.n8n = {
    enable = true;
    webhookUrl = "https://${apiAddr}";
    settings = {
      inherit (config.links.api) port;
    };
  };

  systemd.services.n8n.environment = {
      N8N_LISTEN_ADDRESS = "127.0.0.1";
      N8N_ENDPOINT_WEBHOOK = "api";
      N8N_ENDPOINT_WEBHOOK_TEST = "test";
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

  services.oauth2-proxy.nginx.virtualHosts.${apiAddr} = { };
}
