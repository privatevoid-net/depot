{ pkgs, lib, config, ... }:
{
  _module.args.tools = (import ./.).all { inherit pkgs lib config; };
}
