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

  security.acme.acceptTerms = true;
  security.acme.maxConcurrentRenewals = 0;
  security.acme.defaults = {
    email = depot.lib.meta.adminEmail;
    extraLegoFlags = lib.flatten [
      (map (x: [ "--dns.resolvers" x ]) authoritativeServers)
      "--dns-timeout" "30"
    ];
    credentialsFile = pkgs.writeText "acme-exec-config" ''
      EXEC_PATH=${execScript}
      EXEC_ENV_FILE=${config.age.secrets.acmeDnsApiKey.path}
      EXEC_SEQUENCE_INTERVAL=0
    '';
  };

  systemd.services = lib.mapAttrs' (name: value: {
    name = "acme-${name}";
    value = {
      distributed.enable = value.dnsProvider != null;
      preStart = let
        serverList = lib.pipe authoritativeServers [
          (map (x: "@${x}"))
          (map (lib.replaceStrings [":53"] [""]))
          lib.escapeShellArgs
        ];
        domainList = lib.pipe ([ value.domain ] ++ value.extraDomainNames) [
          (map (x: "${x}."))
          (map (lib.replaceStrings ["*"] ["x"]))
          lib.unique
          lib.escapeShellArgs
        ];
      in ''
        echo Testing availability of authoritative DNS servers
        for i in {1..60}; do
          ${pkgs.dig}/bin/dig +short ${serverList} ${domainList} >/dev/null && break
          echo Retry [$i/60]
          sleep 10
        done
        echo Available
      '';
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = lib.mkForce "100ms";
        RestartMaxDelaySec = 30;
        RestartSteps = 5;
        RestartMode = "direct";
      };
    };
  }) config.security.acme.certs;
}
