{ inputs, packages, tools }:
with tools.vhosts;
let inherit (tools) domain; in
{
  # websites
  www = static packages.landing.webroot // { default = true; };
  draw = static packages.excalidraw.webroot;
  "docs.hyprspace" = static "${inputs.hyprspace.packages.docs}/share/www/hyprspace-docs";

  # PSA sites
  stop-using-nix-env = static packages.stop-using-nix-env.webroot;

  top-level = redirect "https://www.${domain}$request_uri" // { serverName = domain; };
}
