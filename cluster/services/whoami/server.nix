{ depot, ... }:

{
  services.nginx.virtualHosts."whoami.${depot.lib.meta.domain}" = {
    locations = {
      "/".return = ''200 "$remote_addr\n"'';
      "/online".return = ''200 "CONNECTED_GLOBAL\n"'';
    };
  };
}
