{ config, inputs, lib, pkgs, tools, ... }:

let
  importWebsites = expr: import expr {
    tools = tools.nginx;
    packages = inputs.self.packages.${pkgs.system};
  };

  websites = tools.nginx.mappers.mapSubdomains (importWebsites ./websites.nix);

  extraWebsites = importWebsites ./extra-sites.nix;
in {
  services.nginx.virtualHosts = websites // extraWebsites;
}
