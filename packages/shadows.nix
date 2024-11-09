{ lib, ... }:

{
  perSystem = { inputs', self', ... }: {
    # much like overlays, shadows can *shadow* packages in nixpkgs
    # unlike overlays, shadows don't cause a nixpkgs re-evaluation
    # this is a hack for dealing with poorly written NixOS modules
    # that don't provide a `package` option to perform overrides

    options.shadows = lib.mkOption {
      type = with lib.types; lazyAttrsOf package;
      default = {
        jitsi-meet = self'.packages.jitsi-meet-insecure;
      };
    };
  };
}
