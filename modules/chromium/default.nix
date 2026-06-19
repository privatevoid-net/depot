{ depot', ... }:

{
  programs.chromium = {
    enable = true;
  };

  environment.systemPackages = with depot'.inputs.nix-crx.packages; [
    bitwarden
    i-still-dont-care-about-cookies
    privacy-badger
    sponsorblock
    ublock-origin
  ];
}