hostName:
{ depot, lib, ... }:

let
  cluster = import ./. { inherit lib depot hostName; };
in

{
  _module.args.cluster = {
    inherit (cluster.config) vars;
    inherit (cluster.config.vars) hosts;
    inherit (cluster) config;
  };
  imports = cluster.config.out.injectedNixosConfig;
}
