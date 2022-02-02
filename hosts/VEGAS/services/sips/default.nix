{ config, inputs, pkgs, tools, ... }:
let
  host = tools.identity.autoDomain "sips";

  inherit (inputs.self.packages.${pkgs.system}) sips;

  connStringNet = "host=127.0.0.1 sslmode=disable dbname=sips user=sips";
  connString = "host=/var/run/postgresql dbname=sips user=sips";

  sipsctl = pkgs.runCommandNoCC "sipsctl-with-env" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    makeWrapper ${sips}/bin/sipsctl $out/bin/sipsctl \
      --set PGPASSFILE ${config.age.secrets.sips-db-credentials.path} \
      --add-flags '--dbdriver postgres --db "${connStringNet}"'

      ln -s ${sips}/share $out/share
  '';
in
{
  age.secrets.sips-db-credentials = {
    file = ../../../../secrets/sips-db-credentials.age;
    mode = "0400";
  };

  reservePortsFor = [ "sips" "sipsInternal" "sipsIpfsApiProxy" ];

  systemd.services.sips = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    requires = [ "sips-ipfs-api-proxy.service" ]; 
    serviceConfig = {
      ExecStart = "${sips}/bin/sips --dbdriver postgres --db \"${connString}\" --addr 127.0.0.1:${config.portsStr.sipsInternal} --api http://127.0.0.1:${config.portsStr.sipsIpfsApiProxy} --apitimeout 604800s";
      PrivateNetwork = true;
      DynamicUser = true;
    };
    environment.PGPASSFILE = config.age.secrets.sips-db-credentials.path;
  };

  systemd.services.sips-ipfs-api-proxy = {
    after = [ "network.target" "sips.service" ];
    bindsTo = [ "sips.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat tcp4-listen:${config.portsStr.sipsIpfsApiProxy},fork,reuseaddr,bind=127.0.0.1 unix-connect:/run/ipfs/ipfs-api.sock";
      PrivateNetwork = true;
      DynamicUser = true;
      SupplementaryGroups = "ipfs";
    };
    unitConfig.JoinsNamespaceOf = "sips.service";
  };

  systemd.services.sips-proxy = {
    after = [ "network.target" "sips.service" ];
    bindsTo = [ "sips.service" ];
    requires = [ "sips-proxy.socket" ];
    serviceConfig = {
      ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${config.portsStr.sipsInternal}";
      PrivateNetwork = true;
      DynamicUser = true;
      SupplementaryGroups = "ipfs";
    };
    unitConfig.JoinsNamespaceOf = "sips.service";
  };

  systemd.sockets.sips-proxy = {
    wantedBy = [ "sockets.target" ];
    after = [ "network.target" ];
    socketConfig = {
      ListenStream = "127.0.0.1:${config.portsStr.sips}";
    };
  };

  environment.systemPackages = [ sipsctl ];

  services.nginx.virtualHosts.${host} = tools.nginx.vhosts.proxy "http://127.0.0.1:${config.portsStr.sips}";
}
