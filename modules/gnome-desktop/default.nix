{ pkgs, ... }:

{
  imports = [
    ./settings.nix
  ];

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-logs
    gnome-music
    gnome-console
    gnome-photos
    gnome-tour
    orca
    showtime
    snapshot
    totem
    yelp
  ];
}
