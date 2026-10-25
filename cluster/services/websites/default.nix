{ config, depot, lib, ... }:

let
  inherit (depot.lib.meta) domain;
in

{
  services.websites = {
    nodes = {
      oldStatic = [ "VEGAS" ];
    };
    nixos.oldStatic = [
      ./old-static
      ./old-static/jokes.nix
    ];
  };

  monitoring.blackbox.targets = {
    web = {
      address = "https://www.${domain}";
      module = "https2xx";
    };
  };

  dns.records = let
    oldStaticAddr = [ depot.hours.VEGAS.interfaces.primary.addrPublic ];
  in {
    autoconfig.target = oldStaticAddr;

    ktp.target = oldStaticAddr;
    legacy.target = oldStaticAddr;

    # jokes
    "bone-ds-dc.com-ldap".target = oldStaticAddr;
    rzentrale.target = oldStaticAddr;
    wunschnachricht.target = oldStaticAddr;
  };

  ways = config.lib.forService "websites" {
    bomed = {
      static = { depot', ... }: depot'.packages.ldap-entry-point.webroot;
      domainSuffix = "lol";
    };
    zedless = {
      static = { pkgs, ... }: pkgs.emptyDirectory;
      extras.locations."/".return = "302 https://github.com/zedless-editor/zedless";
      domainSuffix = "org";
    };
    manic = {
      static = { depot', ... }: "${depot'.inputs.manic-systems-web.packages.default}/share/web/dist";
      domainSuffix = "systems";
    };
    www = {
      static = { depot', ... }: depot'.packages.landing;
      extras.default = true;
    };
    draw = {
      static = { depot', ...}: depot'.packages.excalidraw;
    };
    "docs.hyprspace" = {
      static = { depot', ... }: "${depot'.inputs.hyprspace.packages.docs}/share/www/hyprspace-docs";
    };
    stop-using-nix-env = {
      static = { depot', ... }: depot'.packages.stop-using-nix-env;
    };
    top-level = {
      name = "@";
      static = { pkgs, ... }: pkgs.emptyDirectory;
      extras.locations."/".return = "301 https://www.${domain}$request_uri";
    };
  };
}
