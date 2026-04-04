{ cluster, config, lib, ... }:

{
  nix.settings = {
    substituters = [
      "http://cache.titan.hyprspace?priority=100"
    ];
    trusted-public-keys = [
      "cache.titan.hyprspace:UCWg5yQKM+kWPgbe4tIh3X74+g5J/FjykC5Bpbl6bbM="
    ];
  };
}
