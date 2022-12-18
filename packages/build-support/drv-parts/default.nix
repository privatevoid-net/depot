{ config, inputs, ... }:

{
  imports = [
    ./backends
    ./dependency-sets
  ];
  _module.args = {
    drv-backends = inputs.drv-parts.drv-backends // config.drv-backends;
  };
}
