{ config, lib, pkgs, ... }:

let
  cfg = config.services.nginx.countersiege;

  bomb = pkgs.fetchurl {
    url = "https://github.com/google/google-ctf/raw/8ea1054a4a6af49e8cf14e10896dc94d73126a29/2019/finals/misc-stuffed-finals/app/bomb.br";
    sha256 = "sha256-q0uzkieZIloW2roWy7wnj8lZMbCYJWxNHBryWg/S2X4=";
  };

  bombConfig = {
    alias = bomb;
    extraConfig = ''
      add_header Content-Encoding "br";
      add_header Content-Disposition "inline";
      types { }
      default_type application/html;
      limit_rate 16k;
    '';
  };
in

{
  options.services.nginx = {
    countersiege = {
      locations = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
    };
    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ config, ... }: {
        options.countersiege = {
          enable = lib.mkEnableOption "Countersiege" // { default = true; };
          locations = lib.mkOption {
            type = lib.types.listOf lib.types.str;
          };
        };
        config = {
          locations = lib.mkIf config.countersiege.enable (lib.genAttrs config.countersiege.locations (lib.const bombConfig));
          countersiege = {
            inherit (cfg) locations;
          };
        };
      }));
    };
  };

  config.services.nginx = {
    countersiege.locations = [
      "~ ^/\\.env$"
      "~ ^/\\.env\\."
      "~ ^/\\.DS_Store"
      # comedy gold
      "~ ^/cgi-bin/"
      "~ ^/wp-admin/"
      "~ ^/wp-config\\.php"
      # docker
      "~ ^/docker-compose"
      # cloud credentials
      "~ ^/\\.aws/"
      "~ ^/aws/credentials"
      # editor config directories
      "~ ^/\\.idea/"
      "~ ^/\\.vscode/"
      # .git, .github, .gitlab-ci.yml
      "~ ^/\\.git"
      # java shit
      "~ ^/actuator/"
      "~ ^/application\\.properties$"
      # random vendor shit
      "~ ^/api/sonicos/"
      "~ ^/sslvpnLogin\\.html$"
      # ms exchange
      "~ ^/ecp/Current/"
      "~ ^/owa/auth/"
    ];
  };
}
