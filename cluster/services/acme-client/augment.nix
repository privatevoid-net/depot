{ config, pkgs, ... }:

let
  lift = config;
in

{
  nowhere.names = {
    "acme-v02.api.letsencrypt.org" = "stepCa";
  };

  nodes.nowhere = { config, ... }: {
    links.stepCa.protocol = "https";

    environment.etc.step-ca-password.text = "";

    services = {
      step-ca = {
        enable = true;
        address = config.links.stepCa.ipv4;
        inherit (config.links.stepCa) port;
        intermediatePasswordFile = "/etc/step-ca-password";
        settings = {
          root = "${lift.nowhere.certs.ca}/ca.pem";
          crt = "${lift.nowhere.certs.intermediate}/cert.pem";
          key = "${lift.nowhere.certs.intermediate}/cert-key.pem";
          address = config.links.stepCa.tuple;
          db = {
            type = "badgerv2";
            dataSource = "/var/lib/step-ca/db";
          };
          authority.provisioners = [
            {
              type = "ACME";
              name = "snakeoil";
              challenges = [
                "dns-01"
                "http-01"
              ];
            }
          ];
        };
      };

      nginx.virtualHosts = {
        "acme-v02.api.letsencrypt.org".locations."/".extraConfig = ''
          rewrite /directory /acme/snakeoil/directory break;
        '';
      };
    };
  };

  defaults.environment.etc."dummy-secrets/acmeDnsApiKey".text = "ACME_DNS_DIRECT_STATIC_KEY=simulacrum";
  defaults.environment.etc."dummy-secrets/acmeDnsDirectKey".text = "ACME_DNS_DIRECT_STATIC_KEY=simulacrum";
  defaults.environment.etc."dummy-secrets/acmeDnsDbCredentials".text = "PGPASSWORD=simulacrum";
}
