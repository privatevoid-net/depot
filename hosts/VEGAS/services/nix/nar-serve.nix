{ inputs, pkgs, tools, ... }:

{
  systemd.services.nar-serve = {
    enable = true;
    serviceConfig = {
      DynamicUser = true;
      User = "nar-serve";
    };
    script = "${inputs.nar-serve.defaultPackage."${pkgs.system}"}/bin/nar-serve";
    environment.NAR_CACHE_URL = "https://cache.${tools.meta.domain}";
  };
}
