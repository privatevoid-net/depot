{ pkgs, lib, config, inputs, tools, ... }:
let
  fixPriority = x: if config.services.hydra.enable
  then lib.mkForce x
  else x;
in {
  nix = {
    package = inputs.nix-super.defaultPackage.${pkgs.system};

    trustedUsers = [ "root" "@wheel" "@admins" ];

    extraOptions = fixPriority ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
      flake-registry = https://git.${tools.meta.domain}/private-void/registry/-/raw/master/registry.json
      
      # For Hercules CI agent
      narinfo-cache-negative-ttl = 0
    '';

    binaryCaches = [ "https://cache.${tools.meta.domain}" ];
    binaryCachePublicKeys = [ "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg=" ];

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
