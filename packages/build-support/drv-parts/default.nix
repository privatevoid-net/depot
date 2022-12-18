{ config, inputs, ... }:

{
  imports = [
    ./backends
  ];
  _module.args = {
    drv-backends = inputs.drv-parts.drv-backends // config.drv-backends;
  };
}
