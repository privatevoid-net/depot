{ cluster, config, lib, pkgs, ... }:

let
  lift = config;

  cfsslConfigIntermediateCA = pkgs.writeText "simulacrum-cfssl-config.json" (builtins.toJSON {
    signing = {
      default.expiry = "8760h";
      profiles.intermediate = {
        expiry = "8760h";
        usages = [
          "cert sign"
          "crl sign"
        ];
        ca_constraint = {
          is_ca = true;
          max_path_len = 1;
        };
      };
    };
  });

  caCsr = pkgs.writeText "simulacrum-ca-csr.json" (builtins.toJSON {
    CN = "Simulacrum Root CA";
  });

  ca = pkgs.runCommand "simulacrum-snakeoil-ca" {
    nativeBuildInputs = [
      pkgs.cfssl
    ];
  } ''
    mkdir $out
    cfssl gencert --initca ${caCsr} | cfssljson --bare $out/ca
  '';

  genCert = extraFlags: csrData: let
    csr = pkgs.writeText "simulacrum-csr.json" (builtins.toJSON csrData);
  in pkgs.runCommand "simulacrum-snakeoil-cert" {
    nativeBuildInputs = [
      pkgs.cfssl
    ];
  } ''
    mkdir $out
    cfssl gencert ${lib.escapeShellArgs ([
      "--ca=file:${ca}/ca.pem"
      "--ca-key=file:${ca}/ca-key.pem"
    ] ++ extraFlags ++ [
      csr
    ])} | cfssljson --bare $out/cert
  '';

  genHostCert = hostname: genCert [ "--hostname=${hostname}" ] { CN = hostname; };

  getNodeAddr = node: (builtins.head config.nodes.${node}.networking.interfaces.eth1.ipv4.addresses).address;
in

{
  imports = [
    ./options.nix
  ];
  defaults = {
    networking.hosts."${getNodeAddr "nowhere"}" = lib.attrNames config.nowhere.names;
    security.pki.certificateFiles = [
      "${ca}/ca.pem"
    ];
  };

  nowhere.certs = {
    inherit ca;
    intermediate = genCert [ "--config=${cfsslConfigIntermediateCA}" "--profile=intermediate" ] {
      CN = "Simulacrum Intermediate CA";
    };
  };

  nodes.nowhere = { config, depot, ... }: {
    imports = [
      depot.nixosModules.reflection
    ];
    networking = {
      firewall.allowedTCPPorts = [ 443 ];
      interfaces.eth1.ipv4.routes = lib.mapAttrsToList (name: hour: {
        address = hour.interfaces.primary.addrPublic;
        prefixLength = 32;
        via = getNodeAddr name;
      }) depot.gods.fromLight;
      nameservers = map (name: depot.hours.${name}.interfaces.primary.addrPublic) cluster.config.services.dns.nodes.authoritative;
    };
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = lib.mapAttrs (name: link: let
        cert = genHostCert name;
      in {
        forceSSL = true;
        sslCertificate = "${cert}/cert.pem";
        sslCertificateKey = "${cert}/cert-key.pem";
        locations."/" = {
          proxyPass = config.links.${link}.url;
          extraConfig = "proxy_ssl_verify off;";
        };
      }) lift.nowhere.names;
    };
  };
}
