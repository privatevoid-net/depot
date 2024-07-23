{ lib, ... }:

let
  pins = import ../sources;
in

{
  perSystem = { config, ... }: {
    catalog.depot = {
      packages = lib.mapAttrs (name: package: {
        description = "Package: ${name}";
        actions = lib.mkMerge [
          {
            build = {
              description = "Build this package.";
              command = "nix build -L '${builtins.unsafeDiscardStringContext package.drvPath}^*'";
            };
          }
          (lib.mkIf (pins ? ${name}) {
            updatePin = {
              description = "Update this package's source pin.";
              command = "${lib.getExe config.packages.pin} update ${name}";
            };
          })
        ];
      }) config.packages;
    };
  };
}
