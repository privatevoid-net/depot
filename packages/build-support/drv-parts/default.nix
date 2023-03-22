{ inputs, ... }:
{
  perSystem = { config, ... }: {
    imports = [
      ./backends
      ./dependency-sets
    ];
    _module.args = {
      drv-backends = inputs.drv-parts.modules.drv-parts // config.drv-backends;
    };
  };
}