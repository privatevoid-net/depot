{ cluster, config, lib, pkgs, ... }:

let
  sentinelFile = "/var/lib/consul/nixos-acl-bootstrapped";
  bootstrapTokenFile = "/run/keys/consul-bootstrap-token";
  bootstrapConfig = "consul-bootstrap-config.json";
  writeRules = rules: pkgs.writeText "consul-policy.json" (builtins.toJSON rules);
in

{
  systemd.services = {
    consul-acl-bootstrap = {
      requires = [ "consul.service" ];
      after = [ "consul.service" ];
      wantedBy = [ "multi-user.target" ];
  
      unitConfig.ConditionPathExists = "!${sentinelFile}";
      serviceConfig = {
        Type = "oneshot";
        PrivateTmp = true;
      };
      environment.CONSUL_HTTP_ADDR = config.links.consulAgent.tuple;
      path = [
        config.services.consul.package
        pkgs.jq
      ];
      script = ''
        umask 77
        if consul acl bootstrap --format=json > ${bootstrapConfig}; then
          echo Bootstrapping:
          jq -r .SecretID < ${bootstrapConfig} > ${bootstrapTokenFile}
          export CONSUL_HTTP_TOKEN_FILE=${bootstrapTokenFile}
          consul acl policy create --name operator-read --description "Read-only operator actions" --rules @${writeRules { operator = "read"; }}
          consul acl policy create --name smt-read --description "Allow reading the encrypted system management token" --rules @${writeRules { key_prefix."secrets/locksmith/consul-systemManagementToken/".policy = "read"; }}
          consul acl token update --id 00000000-0000-0000-0000-000000000002 --append-policy-name operator-read --append-policy-name smt-read
        else
          echo Bootstrap is already in progress elsewhere.
          touch ${sentinelFile}
        fi
      '';
    };
    locksmith-provider-consul = {
      unitConfig.ConditionPathExists = bootstrapTokenFile;
      distributed.enable = lib.mkForce false;
      environment = {
        CONSUL_HTTP_ADDR = config.links.consulAgent.tuple;
        CONSUL_HTTP_TOKEN_FILE = bootstrapTokenFile;
      };
      postStop = ''
        rm -f ${bootstrapTokenFile}
        touch ${sentinelFile}
      '';
    };
  };

  services.locksmith.providers.consul = {
    wantedBy = [ "consul-acl-bootstrap.service" ];
    after = [ "consul-acl-bootstrap.service" ];
    secrets.systemManagementToken = {
      nodes = cluster.config.services.consul.nodes.agent;
      checkUpdate = "test -e ${bootstrapTokenFile}";
      command = "cat ${bootstrapTokenFile}";
    };
  };
}
