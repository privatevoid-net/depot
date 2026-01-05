{ depot, lib, options, ... }:

{
  imports = [
    depot.inputs.agenix.nixosModules.age
  ];

  system.activationScripts.agenixInstall.deps = lib.mkIf (options ? sops) [ "setupSecrets" ];
}
