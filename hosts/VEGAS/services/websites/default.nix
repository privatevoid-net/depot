{ depot, ... }:

let
  importWebsites = expr: import expr {
    tools = depot.lib.nginx;
    inherit (depot) packages;
  };

  websites = depot.lib.nginx.mappers.mapSubdomains (importWebsites ./websites.nix);
in {
  services.nginx.virtualHosts = websites;
}
