{ config, inputs, self, ... }:

{
  lib.hours.specialArgs = {
    depot = { inherit inputs; } // self // config;
  };
}
