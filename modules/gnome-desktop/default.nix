{ pkgs, ... }:

{
  imports = [
    ./settings.nix
    ./sound-theme.nix
  ];

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    gnome-calculator
    gnome-logs
    gnome-maps
    gnome-music
    gnome-console
    gnome-photos
    gnome-tour
    orca
    showtime
    simple-scan
    snapshot
    totem
    yelp
  ];

  services.avahi.enable = false;
}
