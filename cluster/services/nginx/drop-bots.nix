{ lib, ... }:

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

  config = {
    services.nginx.appendHttpConfig = ''
      map $http_user_agent $drop_ua {
        default 0;
        ~*Amazonbot 1;
        ~*BacklinksExtendedBot 1;
        ~*Bytespider 1;
        ~*ClaudeBot 1;
        ~*DataForSeoBot 1;
        ~*DotBot 1;
        ~*GPTBot 1;
        ~*Googlebot 1;
        ~*ImagesiftBot 1;
        ~*MJ12Bot 1;
        ~*OAI-SearchBot 1;
        ~*SemrushBot 1;
        ~*YandexBot 1;
        ~*bingbot 1;
        ~*meta-externalagent 1;
        "~*Windows NT 6\.1" 1;
        "~*Android [56]\.0" 1;
        "~*Chrome/[3-9][0-9]\." 1;
        ~*Brightbot 1;
        ~*AhrefsBot 1;
        ~*TerraCotta 1;
        "~*Hello from Palo Alto Networks" 1;
        "~*Edg/[0-9]" 1;
        }
    '';

    environment.etc."fail2ban/filter.d/nginx-drop-status-444.conf".text = ''
      [Definition]
      journalmatch = _SYSTEMD_UNIT=nginx.service + _COMM=nginx + SYSLOG_IDENTIFIER=nginx_access
      failregex = class=default vhost=.* remote_addr=<ADDR> .* status=444 .*
    '';

    services.fail2ban.jails.nginx.settings = {
      filter = "nginx-drop-status-444";
      banaction = "xdp";
      findtime = "3600";
      maxretry = "2";
      "bantime.maxtime" = "672h";
      "bantime.rndtime" = "10m";
      "bantime.factor" = "16";
    };
  };
}
