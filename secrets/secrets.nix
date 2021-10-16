let
  max = (import ../users/max/userinfo.nix null).sshKeys;
  hosts = import ../hosts;
  systemKeys = x: x.ssh.id.publicKey or null;
in with hosts;
{
  "hydra-s3.age".publicKeys = max ++ map systemKeys [ styx ];
  "hydra-db-credentials.age".publicKeys = max ++ map systemKeys [ styx ];
  "gitea-db-credentials.age".publicKeys = max ++ map systemKeys [ git ];
  "oauth2_proxy-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS ];
}
