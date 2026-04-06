let
  max = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL max@TITAN"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmdWfmAs/0rno8zJlhBFMY2SumnHbTNdZUXJqxgd9ON max@jericho"
  ];
  hosts = builtins.mapAttrs (_: v: v.config.reflection)
    (builtins.getFlake "git+file://${builtins.getEnv "PWD"}").nixosConfigurations;
  systemKeys = x: x.ssh.id.publicKey or null;
in with hosts;
{
  "cluster/services/dns/acme-dns-direct-key.age".publicKeys = max ++ map systemKeys [ checkmate grail thousandman VEGAS prophet ];
  "cluster/services/monitoring/secrets/grafana-db-credentials.age".publicKeys = max ++ map systemKeys [ VEGAS prophet ];
  "cluster/services/monitoring/secrets/grafana-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS prophet ];
  "cluster/services/monitoring/secrets/secret-monitoring/blackbox.age".publicKeys = max ++ map systemKeys [ checkmate grail prophet ];
  "cluster/services/storage/secrets/heresy-encryption-key.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "cluster/services/storage/secrets/garage-rpc-secret.age".publicKeys = max ++ map systemKeys [ grail VEGAS prophet ];
  "cluster/services/storage/secrets/storage-box-credentials.age".publicKeys = max ++ map systemKeys [ grail VEGAS prophet ];
  "secrets/dovecot-ldap-token.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/hyprspace-key-checkmate.age".publicKeys = max ++ map systemKeys [ checkmate ];
  "secrets/hyprspace-key-grail.age".publicKeys = max ++ map systemKeys [ grail ];
  "secrets/hyprspace-key-VEGAS.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/hyprspace-key-prophet.age".publicKeys = max ++ map systemKeys [ prophet ];
  "secrets/hyprspace-key-thousandman.age".publicKeys = max ++ map systemKeys [ thousandman ];
  "secrets/nextcloud-adminpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/nextcloud-dbpass.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/oauth2_proxy-secrets.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/postfix-ldap-mailboxes.age".publicKeys = max ++ map systemKeys [ VEGAS ];
  "secrets/wireguard-key-storm-VEGAS.age".publicKeys = max ++ map systemKeys [ VEGAS ];
}
