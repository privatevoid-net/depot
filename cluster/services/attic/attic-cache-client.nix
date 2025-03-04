{ depot, ... }:

{
  nix.settings.substituters = [ "https://cache-api.${depot.lib.meta.domain}/nix-store" ];
}
