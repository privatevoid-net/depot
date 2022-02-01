let
  max = (import ../users/max/userinfo.nix null).sshKeys;
  hosts = import ../hosts;
  systemKeys = x: x.ssh.id.publicKey or null;
in with hosts;
{
  "acme-dns-key.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "coturn-static-auth.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "ghost-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "gitlab-initial-root-password.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "gitlab-openid-secret.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "gitlab-runner-registration.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "gitlab-secret-db.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "gitlab-secret-jws.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "gitlab-secret-otp.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "gitlab-secret-secret.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "hydra-bincache.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "hydra-builder-key.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "hydra-db-credentials.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "hydra-s3.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "hyprspace-key-VEGAS.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "keycloak-dbpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "matrix-appservice-discord-token.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "minio-console-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "minio-root-credentials.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "nextcloud-adminpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "nextcloud-dbpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "oauth2_proxy-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "postfix-ldap-mailboxes.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "synapse-db.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "synapse-keys.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "synapse-ldap.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "synapse-turn.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "wireguard-key-wgautobahn.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "vpn-host-key-VEGAS.age".publicKeys = max ++ map systemKeys [ VEGAS ];
}
