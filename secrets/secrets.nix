let
  max = (import ../users/max/userinfo.nix null).sshKeys;
  hosts = import ../hosts;
  systemKeys = x: x.ssh.id.publicKey or null;
in with hosts;
{
  "discourse-adminpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "discourse-dbpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "gitea-db-credentials.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "hydra-db-credentials.age".publicKeys = max ++ map systemKeys [ styx ];
  "hydra-s3.age".publicKeys = max ++ map systemKeys [ styx ];
  "matrix-appservice-discord-token.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "oauth2_proxy-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "postfix-ldap-mailboxes.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "synapse-db.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "synapse-keys.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "synapse-ldap.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "synapse-turn.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "wireguard-key-wgautobahn.age".publicKeys = max ++ map systemKeys [ VEGAS ];
}
