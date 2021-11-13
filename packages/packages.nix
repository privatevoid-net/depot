{ pkgs, ... }: {
  hyprspace = pkgs.callPackage ./networking/hyprspace { iproute2mac = null; };

  privatevoid-smart-card-ca-bundle = pkgs.callPackage ./data/privatevoid-smart-card-certificate-authority-bundle.nix { };
}
