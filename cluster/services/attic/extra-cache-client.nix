{ cluster, config, lib, ... }:

{
  nix.settings.trusted-public-keys = [
    "cache.titan.hyprspace:UCWg5yQKM+kWPgbe4tIh3X74+g5J/FjykC5Bpbl6bbM="
  ];

  services.ncro.instances.internal.settings.upstreams = [
    {
      url = "http://cache.titan.hyprspace";
      priority = 100;
    }
  ];
}
