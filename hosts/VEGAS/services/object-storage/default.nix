{ config, lib, pkgs, tools, ... }:
with tools.nginx;
let
  addrSplit' = builtins.split ":" config.services.minio.listenAddress;
  addrSplit = builtins.filter builtins.isString addrSplit';
  host' = builtins.head addrSplit;
  host = if host' == "" then "127.0.0.1" else host';
  port = builtins.head (builtins.tail addrSplit);

  minioConsole = pkgs.callPackage ./console.nix {};
in
{
  reservePortsFor = [ "minioConsole" ];

  age.secrets.minio-root-credentials = {
    file = ../../../../secrets/minio-root-credentials.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
  age.secrets.minio-console-secrets = {
    file = ../../../../secrets/minio-console-secrets.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
  services.minio = {
    enable = true;
    # requires https://github.com/NixOS/nixpkgs/pull/123834
    # rootCredentialsFile = "/dev/null";
    dataDir = [ "/srv/storage/objects" ];
    browser = true;
  };
  systemd.services.minio.serviceConfig = {
    EnvironmentFile = config.age.secrets.minio-root-credentials.path;
    Slice = "remotefshost.slice";
  };
  services.nginx.virtualHosts = mappers.mapSubdomains {
    # TODO: vhosts.proxy?
    "object-storage" = vhosts.basic // {
      locations = {
        "/".proxyPass = "http://${host}:${port}";
        "= /dashboard".proxyPass = "http://${host}:${port}";
      };
      extraConfig = "client_max_body_size 4G;";
    };
    "console.object-storage" = vhosts.basic // {
      locations = {
        "/".proxyPass = "http://127.0.0.1:${config.portsStr.minioConsole}";
      };
    };
    "cdn" = lib.recursiveUpdate (vhosts.proxy "http://${host}:${port}/content-delivery$request_uri") {
      locations."= /".return = "302 /index.html";
    };
  };
  services.oauth2_proxy.nginx.virtualHosts = [ "console.object-storage.${tools.meta.domain}" ];
  systemd.services.minio-console = {
    enable = true;
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${minioConsole}/bin/console server --port ${config.portsStr.minioConsole}";
      EnvironmentFile = config.age.secrets.minio-console-secrets.path;
      DynamicUser = true;
      User = "minio-console";
    };
    environment = {
      CONSOLE_MINIO_REGION = "us-east-1";
      # TODO: external or internal?
      CONSOLE_MINIO_SERVER = "https://object-storage.${tools.meta.domain}";
    };
    path = [ pkgs.glibc.bin ];
  };
}
