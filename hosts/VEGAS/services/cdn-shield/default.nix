{ config, lib, toolsets, ... }:

let
  tools = toolsets.nginx {
    inherit lib config;
    domain = "cdn-shield.${toolsets.meta.domain}";
  };
in
{
  services.nginx.virtualHosts = tools.mappers.mapSubdomains (import ./shields.nix { inherit tools; });
}
