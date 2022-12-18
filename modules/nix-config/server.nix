{ pkgs, lib, config, inputs, tools, ... }:

{
  nix = {
    package = inputs.nix-super.packages.${pkgs.system}.default;

    settings = {
      trusted-users = [ "root" "@wheel" "@admins" ];
      binary-caches = [ "https://cache.${tools.meta.domain}" ];
      trusted-public-keys = [ "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg=" ];
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
      flake-registry = https://git.${tools.meta.domain}/private-void/registry/-/raw/master/registry.json
      
      # For Hercules CI agent
      narinfo-cache-negative-ttl = 0
    '';

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
