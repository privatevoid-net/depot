{
  perSystem = { builders, lib, pkgs, self', ... }: {
    packages.ldap-entry-point = with pkgs; let
      site = stdenvNoCC.mkDerivation rec {
        pname = "ldap-entry-point";
        version = "1.0.0";
        src = builders.hydrateAssetDirectory ./src;
        buildCommand = ''
          unpackPhase
          mkdir -p $out/share/www
          cp -r $sourceRoot $out/share/www/${pname}
        '';
        passthru.webroot = "${site}/share/www/${site.pname}";
      };
    in site;
  };
}
