{ config, lib, ... }:
with lib;

{
  options.age.secrets = mkOption {
    type = types.attrsOf (types.submodule ({ name, config, ... }: {
      config.path = lib.mkForce "/etc/dummy-secrets/${name}";
    }));
  };
  config.environment.etc = mapAttrs' (name: secret: {
    name = removePrefix "/etc/" secret.path;
    value = mapAttrs (const mkDefault) {
      user = secret.owner;
      inherit (secret) mode group;
      text = builtins.hashString "md5" name;
    };
  }) config.age.secrets;

  config.system.activationScripts = {
    agenixChown.text = lib.mkForce "echo using age-dummy-secrets";
    agenixNewGeneration.text = lib.mkForce "echo using age-dummy-secrets";
    agenixInstall.text = lib.mkForce ''
      ln -sf /etc/dummy-secrets /run/agenix
    '';
  };
}
