{ config, lib, ... }:

let
  group = imports: { inherit imports; };

  allModules = lib.mapAttrs (name: _: ./${name})
    (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./.));
in

{
  flake.nixosModules = with config.flake.nixosModules; allModules // {
    machineBase = group [
      agenix
      alloy-structured-metrics
      enterprise
      maintenance
      minimal
      nixos-core
      nixpkgs-config
      port-magic
      reflection
      ssh
      systemd-extras
    ];

    serverBase = group [
      machineBase
      ascensions
      consul-distributed-services
      consul-service-registry
      effect-receiver
      external-storage
      fail2ban
      motd
      networking
      nix-config
      system-recovery
      tested
    ];

    containerBase = group [
      machineBase
      networking
      nix-config
    ];

    backboneBase = group [
      serverBase
    ];

    desktopBase = group [
      machineBase
      app-folders
      blackbox
      bluetooth
      cade
      chromium
      desktop-packages
      fonts
      games
      gnome-desktop
      hidden-apps
      monitors
      networking-client
      nix-config
      nixpak-tricks
      open-in-blackbox
      quiet-boot
      smfh
      zedless
    ];
  };
}
