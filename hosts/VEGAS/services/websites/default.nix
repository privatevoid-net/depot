{ config, lib, tools, ... }:

{
  services.nginx.virtualHosts = tools.nginx.mappers.mapSubdomains (import ./websites.nix { tools = tools.nginx; });
}
