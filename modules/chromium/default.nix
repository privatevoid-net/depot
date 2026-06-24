{ depot', ... }:

let
  extensions = depot'.inputs.nix-crx.packages;
in

{
  programs.chromium = {
    enable = true;
    extraOpts = {
      EnterpriseProfileBadgeToolbarSettings = 1;
      PasswordManagerEnabled = false;
      ExtensionSettings = {
        ${extensions.ublock-origin.id} = {
          toolbar_pin = "force_pinned";
        };
      };
      MandatoryExtensionsForIncognitoNavigation = with extensions; [
        ublock-origin.id
      ];
    };
  };

  environment.systemPackages = with extensions; [
    bitwarden
    i-still-dont-care-about-cookies
    privacy-badger
    sponsorblock
    ublock-origin
  ];
}
