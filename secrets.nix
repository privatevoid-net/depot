let
  max = (import ./users/max/userinfo.nix null).sshKeys;
  hosts = builtins.mapAttrs (_: v: v._module.specialArgs.depot.reflection)
    (builtins.getFlake "git+file://${builtins.getEnv "PWD"}").nixosConfigurations;
  systemKeys = x: x.ssh.id.publicKey or null;
in with hosts;
{
  "cluster/services/dns/acme-dns-direct-key.age".publicKeys = max ++ map systemKeys [ checkmate grail thunderskin VEGAS prophet ];
  "cluster/services/dns/acme-dns-db-credentials.age".publicKeys = max ++ map systemKeys [ checkmate VEGAS prophet ];
  "cluster/services/monitoring/secrets/grafana-db-credentials.age".publicKeys = max ++ map systemKeys [ VEGAS prophet ];
  "cluster/services/monitoring/secrets/grafana-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS prophet ];
  "cluster/services/monitoring/secrets/loki-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "cluster/services/monitoring/secrets/secret-monitoring/blackbox.age".publicKeys = max ++ map systemKeys [ checkmate grail prophet ];
  "cluster/services/monitoring/secrets/tempo-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "cluster/services/storage/secrets/heresy-encryption-key.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "cluster/services/storage/secrets/external-storage-auth-prophet.age".publicKeys = max ++ map systemKeys [ prophet ];
  "cluster/services/storage/secrets/garage-rpc-secret.age".publicKeys = max ++ map systemKeys [ grail VEGAS prophet ];
  "cluster/services/storage/secrets/storage-box-credentials.age".publicKeys = max ++ map systemKeys [ grail VEGAS prophet ];
  "secrets/dovecot-ldap-token.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/gitlab-db-credentials.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/gitlab-initial-root-password.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/gitlab-openid-secret.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/gitlab-secret-db.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/gitlab-secret-jws.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/gitlab-secret-otp.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/gitlab-secret-secret.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/hydra-bincache.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/hydra-builder-key.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/hydra-db-credentials.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/hydra-s3.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/hyprspace-key-checkmate.age".publicKeys = max ++ map systemKeys [ checkmate ];
  "secrets/hyprspace-key-grail.age".publicKeys = max ++ map systemKeys [ grail ];
  "secrets/hyprspace-key-thunderskin.age".publicKeys = max ++ map systemKeys [ thunderskin ];
  "secrets/hyprspace-key-VEGAS.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/hyprspace-key-prophet.age".publicKeys = max ++ map systemKeys [ prophet ];
  "secrets/keycloak-dbpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/nextcloud-adminpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/nextcloud-dbpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/oauth2_proxy-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/postfix-ldap-mailboxes.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/wireguard-key-storm-VEGAS.age".publicKeys = max ++ map systemKeys [ VEGAS ];
}
