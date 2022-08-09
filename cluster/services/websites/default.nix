{ config, ... }:

let
  inherit (config.vars) hosts;

in
{
  services.websites = {
    nodes = {
      host = [ "VEGAS" "prophet" ];
    };
    nixos = {
      host = ./host.nix;
    };
  };
}
