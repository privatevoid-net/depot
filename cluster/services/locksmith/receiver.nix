{ config, lib, pkgs, ... }:

let
  consulCfg = config.services.consul.extraConfig;
  consulIpAddr = consulCfg.addresses.http or "127.0.0.1";
  consulHttpAddr = "${consulIpAddr}:${toString (consulCfg.ports.http or 8500)}";

  kvRoot = "secrets/locksmith";
  kvValue = "recipient/${config.networking.hostName}";
in

{
  systemd.tmpfiles.settings.locksmith = {
    "/run/locksmith".d = {
      mode = "0711";
    };
  };

  systemd.services.locksmith = {
    description = "The Locksmith's Chant";
    wantedBy = [ "multi-user.target" ];
    wants = [ "consul.service" ];
    after = [ "consul.service" ];
    chant.enable = true;
    path = [
      config.services.consul.package
    ];
    environment = {
      CONSUL_HTTP_ADDR = consulHttpAddr;
    };
    serviceConfig = {
      PrivateTmp = true;
      WorkingDirectory = "/tmp";
      IPAddressDeny = [ "any" ];
      IPAddressAllow = [ consulIpAddr ];
      LoadCredential = lib.mkForce [];
    };
    script = ''
      consul kv get --keys ${kvRoot}/ | ${pkgs.gnused}/bin/sed 's,/$,,g' | while read secret; do
        out="$(mktemp -u /run/locksmith/.locksmith-secret.XXXXXXXXXXXXXXXX)"
        if [[ "$(consul kv get --keys "$secret/${kvValue}")" == "$secret/${kvValue}" ]]; then
          owner="$(consul kv get "$secret/owner")"
          group="$(consul kv get "$secret/group")"
          mode="$(consul kv get "$secret/mode")"
          consul kv get "$secret/${kvValue}" | ${pkgs.age}/bin/age --decrypt -i /etc/ssh/ssh_host_ed25519_key -o $out
          chown -v "$owner:$group" $out
          chmod -v "$mode" $out
          mv -v $out "/run/locksmith/$(basename "$secret")"
        fi
      done
    '';
  };
}
