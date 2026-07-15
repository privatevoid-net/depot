{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption toXML mkIf;
  inherit (lib.types) listOf submodule enum ints strMatching bool str nullOr;
  exactNumber = strMatching "[0-9]+(\\.[0-9]+)?" // {
    description = "Exact number (as string)";
  };
in

{
  options.hardware.monitors = {
    layouts = mkOption {
      description = "Monitor layouts.";
      type = listOf (submodule {
        options = {
          layoutMode = mkOption {
            type = enum [ "logical" "physical" ];
            default = "logical";
          };
          monitors = mkOption {
            description = "The monitors in this layout, including mode and position.";
            type = listOf (submodule {
              options = {
                primary = mkOption { type = bool; default = false; };
                position = {
                  x = mkOption { type = ints.unsigned; };
                  y = mkOption { type = ints.unsigned; };
                  scale = mkOption { type = exactNumber; default = "1"; };
                };
                mode = {
                  width = mkOption { type = ints.positive; };
                  height = mkOption { type = ints.positive; };
                  refreshRate = mkOption { type = exactNumber; };
                  colorMode = mkOption { type = nullOr str; default = null; };
                };
                spec = {
                  connector = mkOption { type = str; };
                  vendor = mkOption { type = str; };
                  product = mkOption { type = str; };
                  serial = mkOption { type = str; };
                };
              };
            });
            default = [];
          };
        };
      });
      default = [];
    };
  };

  config = mkIf (config.hardware.monitors.layouts != []) {
    environment.etc."xdg/monitors.xml".source = pkgs.runCommand "monitors.xml" {
      input = toXML config.hardware.monitors.layouts;
      passAsFile = [ "input" ];
      nativeBuildInputs = [
        pkgs.libxslt
      ];
    } "xsltproc ${./transform.xsl} $inputPath > $out";
  };
}
