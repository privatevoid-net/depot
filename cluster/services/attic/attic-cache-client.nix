{ depot, ... }:

{
  services.ncro.instances.internal.settings.upstreams = [
    {
      url = "https://cache-api.${depot.lib.meta.domain}/nix-store";
      priority = 45;
    }
  ];
}
