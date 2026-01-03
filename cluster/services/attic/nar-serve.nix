{ config, depot, depot', ... }:

  let
    mkNarServe = NAR_CACHE_URL: PORT: {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${depot'.inputs.nar-serve.packages.nar-serve}/bin/nar-serve";
      };
      environment = { inherit NAR_CACHE_URL PORT; };
    };
  in
{
  links = {
    nar-serve-self.protocol = "http";
    nar-serve-nixos-org.protocol = "http";
  };

  systemd.services.nar-serve-self = mkNarServe "https://cache.${depot.lib.meta.domain}" config.links.nar-serve-self.portStr;
  systemd.services.nar-serve-nixos-org = mkNarServe "https://cache.nixos.org" config.links.nar-serve-nixos-org.portStr;
}
