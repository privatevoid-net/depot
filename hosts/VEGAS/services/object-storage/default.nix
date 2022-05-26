{ config, inputs, lib, pkgs, tools, ... }:
with tools.nginx;
let
  minioPort = config.portsStr.minio;
  consolePort = config.portsStr.minioConsole;

  mapPaths = lib.mapAttrsRecursive (
    path: value: lib.nameValuePair
      (lib.toUpper (lib.concatStringsSep "_" path))
      (toString value)
  );

  translateConfig = config: lib.listToAttrs (
    lib.collect
      (x: x ? name && x ? value)
      (mapPaths config)
  );
in
{
  reservePortsFor = [ "minio" "minioConsole" ];

  age.secrets.minio-root-credentials = {
    file = ../../../../secrets/minio-root-credentials.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
  services.minio = {
    enable = true;
    rootCredentialsFile = config.age.secrets.minio-root-credentials.path;
    dataDir = [ "/srv/storage/objects" ];
    browser = true;
    listenAddress = "127.0.0.1:${minioPort}";
    consoleAddress = "127.0.0.1:${consolePort}";
  };
  systemd.services.minio.serviceConfig = {
    Slice = "remotefshost.slice";
  };
  services.nginx.virtualHosts = mappers.mapSubdomains {
    # TODO: vhosts.proxy?
    "object-storage" = vhosts.basic // {
      locations = {
        "/".proxyPass = "http://127.0.0.1:${minioPort}";
        "= /dashboard".proxyPass = "http://127.0.0.1:${minioPort}";
      };
      extraConfig = "client_max_body_size 4G;";
    };
    "console.object-storage" = vhosts.basic // {
      locations = {
        "/".proxyPass = "http://127.0.0.1:${consolePort}";
      };
    };
    "cdn" = lib.recursiveUpdate (vhosts.proxy "http://127.0.0.1:${minioPort}/content-delivery$request_uri") {
      locations."= /".return = "302 /index.html";
    };
  };
  systemd.services.minio.environment = translateConfig {
    minio.browser_redirect_url = "https://console.object-storage.${domain}";
    minio.identity_openid = {
      enable = "on";
      display_name = "Private Void Account";
      config_url = "https://login.${domain}/auth/realms/master/.well-known/openid-configuration";
      client_id = "net.privatevoid.object-storage1";
      claim_name = "minio_policy";
      redirect_uri_dynamic = "on";
    };
  };
}
