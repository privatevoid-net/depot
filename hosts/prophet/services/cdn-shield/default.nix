{ config, lib, toolsets, ... }:

let
  tools = toolsets.nginx {
    inherit lib config;
    domain = "cdn-shield.imagine-using-oca.ml";
  };
in
{
  services.nginx.virtualHosts = tools.mappers.mapSubdomains (import ./shields.nix { inherit tools; });
}
