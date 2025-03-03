{ depot, lib, ... }:

{
  nix = {
    package = let
      nix = depot.inputs.nix-super.packages.default;
    in { version = lib.getVersion nix.name; } // nix;

    settings = {
      trusted-users = [ "root" "@wheel" "@admins" ];
      substituters = [ "https://cache.${depot.lib.meta.domain}" ];
      trusted-public-keys = [ "cache.privatevoid.net:SErQ8bvNWANeAvtsOESUwVYr2VJynfuc9JRwlzTTkVg=" ];
    };

    extraOptions = ''
      experimental-features = nix-command flakes cgroups
      use-cgroups = true
      builders-use-substitutes = true
      flake-registry = https://registry.${depot.lib.meta.domain}/flake-registry.json

      # For Hercules CI agent
      narinfo-cache-negative-ttl = 0
    '';

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    daemonCPUSchedPolicy = "batch";
    daemonIOSchedPriority = 7;
  };

  systemd.services.nix-daemon = {
    serviceConfig.Slice = "builder.slice";
    environment.AWS_EC2_METADATA_DISABLED = "true";
  };
}
