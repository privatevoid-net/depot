{ cluster, config, pkgs, ... }:

{
  age.secrets.pdns-api-key-acme = cluster.config.vars.pdns-api-key-secret // { owner = "acme"; };

  security.acme.defaults.credentialsFile = pkgs.writeText "acme-pdns-credentials" ''
    PDNS_API_URL=${cluster.config.links.powerdns-api.url}
    PDNS_API_KEY_FILE=${config.age.secrets.pdns-api-key-acme.path}
  '';
}
