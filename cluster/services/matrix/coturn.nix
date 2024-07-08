{ cluster, depot, ... }:
{
  services.coturn = {
    enable = true;
    no-cli = true;
    realm = depot.lib.meta.domain;

    no-tcp-relay = true;
    min-port = 64000;
    max-port = 65535;
    # TODO: unhardcode
    listening-ips = [ "95.216.8.12" ];

    lt-cred-mech = true;
    use-auth-secret = true;

    static-auth-secret-file = cluster.config.services.matrix.secrets.coturnStaticAuth.path;
    # TODO: acme
    cert = "/etc/coturn/certs/fullchain.pem";
    pkey = "/etc/coturn/certs/privkey.pem";

    extraConfig = ''
      no-tlsv1
      no-tlsv1_1
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=192.168.0.0-192.168.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255
    '';
  };
}
