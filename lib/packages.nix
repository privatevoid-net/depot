{
  lib = { config, ... }: {
    acceptVulnerabilities = drv:
      assert drv.meta ? knownVulnerabilities && builtins.length drv.meta.knownVulnerabilities > 0;
      config.lib.ignoreVulnerabilities drv;

    ignoreVulnerabilities = drv: drv.overrideAttrs (old: {
      meta = old.meta // {
        knownVulnerabilities = [];
      };
    });
  };
}
