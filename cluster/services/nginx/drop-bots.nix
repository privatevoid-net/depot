{ config, lib, ... }:

{
  options.services.nginx.virtualHosts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      extraConfig = ''
        if ($drop_ua = 1) {
          return 444;
        }
      '';
    });
  };
  config.services.nginx.appendHttpConfig = ''
    map $http_user_agent $drop_ua {
      default 0;
      ~*Amazonbot 1;
      ~*Bytespider 1;
      ~*ClaudeBot 1;
      ~*DataForSeoBot 1;
      ~*DotBot 1;
      ~*GPTBot 1;
      ~*Googlebot 1;
      ~*MJ12Bot 1;
      ~*OAI-SearchBot 1;
      ~*SemrushBot 1;
      ~*YandexBot 1;
      ~*bingbot 1;
      ~*meta-externalagent 1;
    }
  '';
}
