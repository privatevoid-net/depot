{ tools, ... }:

{
  services.nginx.virtualHosts = {
    "internal.ai.thevirtualarkade.net" = tools.nginx.vhosts.proxy "http://10.10.2.188:8080";
  };
}
