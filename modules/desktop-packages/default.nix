{ depot, lib, pkgs, ... }:

{
  imports = [
    depot.inputs.nixpak.nixosModules.default
    ./app-folders.nix
    ./cli-apps.nix
    ./mime-assignments.nix
    ./sandboxed-apps.nix
  ];

  security.nixpak = {
    enable = true;
    defaults = { name, ... }: {
      imports = [
        (depot.inputs.nixpak.nixpakModules."preset-${name}" or {})
      ];
      app.package = lib.mkIf (pkgs ? ${name}) pkgs.${name};
      bubblewrap = {
        bind.ro = [
          "/etc/localtime"
        ];
      };
    };
  };
}
