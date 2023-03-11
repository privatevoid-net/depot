{ depot, tools, ... }:

let
  importWebsites = expr: import expr {
    tools = tools.nginx;
    inherit (depot) packages;
  };

  websites = tools.nginx.mappers.mapSubdomains (importWebsites ./websites.nix);

  extraWebsites = importWebsites ./extra-sites.nix;
in {
  services.nginx.virtualHosts = websites // extraWebsites;
}
