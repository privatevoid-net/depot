{ cluster, config, depot, lib, pkgs, ... }:

let
  authoritativeServers = map
    (node: cluster.config.hostLinks.${node}.dnsAuthoritative.tuple)
    cluster.config.services.dns.nodes.authoritative;

  execScript = pkgs.writeShellScript "acme-dns-exec" ''
    action="$1"
    subdomain="''${2%.${depot.lib.meta.domain}.}"
    key="$3"
    umask 77
    source "$EXEC_ENV_FILE"
    headersFile="$(mktemp)"
    echo "X-Direct-Key: $ACME_DNS_DIRECT_STATIC_KEY" > "$headersFile"
    case "$action" in
      present)
        for i in {1..5}; do
          ${pkgs.curl}/bin/curl -X POST -s -f -H "@$headersFile" \
            "${cluster.config.links.acmeDnsApi.url}/update" \
            --data '{"subdomain":"'"$subdomain"'","txt":"'"$key"'"}' && break
          sleep 5
        done
        ;;
    esac
  '';
in

{
  age.secrets.acmeDnsApiKey = {
    file = ../dns/acme-dns-direct-key.age;
    owner = "acme";
  };

  security.acme.defaults = {
    extraLegoFlags = lib.flatten [
      (map (x: [ "--dns.resolvers" x ]) authoritativeServers)
      "--dns-timeout" "30"
    ];
    credentialsFile = pkgs.writeText "acme-exec-config" ''
      EXEC_PATH=${execScript}
      EXEC_ENV_FILE=${config.age.secrets.acmeDnsApiKey.path}
    '';
  };
}
