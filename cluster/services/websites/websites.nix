{ packages, tools }:
with tools.vhosts;
let inherit (tools) domain; in
{
  # websites
  www = static packages.landing.webroot // { default = true; };
  draw = static packages.excalidraw.webroot;

  # PSA sites
  stop-using-nix-env = static packages.stop-using-nix-env.webroot;

  whoami.locations = { # no tls
    "/".return = ''200 "$remote_addr\n"'';
    "/online".return = ''200 "CONNECTED_GLOBAL\n"'';
  };

  top-level = redirect "https://www.${domain}$request_uri" // { serverName = domain; };
}
