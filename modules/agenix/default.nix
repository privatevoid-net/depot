{ config, depot, lib, options, ... }:

{
  imports = [
    depot.inputs.agenix.nixosModules.age
  ];

  system.activationScripts.agenixInstall = lib.mkIf (options ? sops && config.age.secrets != {}) {
    deps = [ "setupSecrets" ];
  };
}
