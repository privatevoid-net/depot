{ config, lib, ... }:
with lib;

let
  hourType = types.submodule {
    imports = [
      ./hour/enterprise.nix
      ./hour/hyprspace.nix
      ./hour/interfaces.nix
      ./hour/nixos.nix
      ./hour/ssh.nix
    ];
  };

  mkHours = description: mkOption {
    inherit description;
    type = with types; attrsOf hourType;
    default = {};
  };
in

{
  options = {
    gods = {
      fromLight = mkHours "Gods-from-Light: The emanations of The Glory";
      fromFlesh = mkHours "Gods-from-Flesh: Mortals who penetrated the Mansus";
      fromNowhere = mkHours "Gods-from-Nowhere: Lesser Hours";
    };
    hours = mkHours "Hours are the incarnate principles of the world." // {
      readOnly = true;
      default = with config.gods; fromLight // fromFlesh // fromNowhere;
    };
  };
}
