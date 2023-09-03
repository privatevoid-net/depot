{ config, lib, ... }:
with lib;

let
  t = {
    string = default: mkOption {
      type = types.str;
      inherit default;
    };
  };
in

{
  options.age.secrets = mkOption {
    type = types.attrsOf (types.submodule ({ name, config, ... }: {
      options = {
        file = mkSinkUndeclaredOptions {};
        owner = t.string "root";
        group = t.string "root";
        mode = t.string "400";
        path = t.string "/etc/dummy-secrets/${name}";
      };
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
}
