{ config, inputs, pkgs, tools, ... }:

  let
    mkNarServe = NAR_CACHE_URL: PORT: {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${inputs.nar-serve.defaultPackage."${pkgs.system}"}/bin/nar-serve";
      };
      environment = { inherit NAR_CACHE_URL PORT; };
    };
  in
{
  reservePortsFor = [
    "nar-serve-self"
    "nar-serve-nixos-org"
  ];

  systemd.services.nar-serve-self = mkNarServe "https://cache.${tools.meta.domain}" config.portsStr.nar-serve-self;
  systemd.services.nar-serve-nixos-org = mkNarServe "https://cache.nixos.org" config.portsStr.nar-serve-nixos-org;
}
