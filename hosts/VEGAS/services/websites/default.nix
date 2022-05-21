{ config, lib, tools, ... }:

let
  importWebsites = expr: import expr { tools = tools.nginx; };

  websites = tools.nginx.mappers.mapSubdomains (importWebsites ./websites.nix);

  extraWebsites = importWebsites ./extra-sites.nix;
in {
  services.nginx.virtualHosts = websites // extraWebsites;
}
