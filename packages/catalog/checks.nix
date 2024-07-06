{ lib, ... }:

{
  perSystem = { config, ... }: {
    catalog.depot = {
      checks = lib.mapAttrs (name: check: {
        description = "NixOS Test: ${name}";
        actions = {
          build = {
            description = "Build this check.";
            command = "nix build -L --no-link '${builtins.unsafeDiscardStringContext check.drvPath}^*'";
          };
          runInteractive = {
            description = "Run interactive driver.";
            command = lib.getExe check.driverInteractive;
          };
        };
      }) config.checks;
    };
  };
}
