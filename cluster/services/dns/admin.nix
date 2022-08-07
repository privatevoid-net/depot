{ cluster, config, hosts, inputs, lib, pkgs, tools, ... }:

let
  inherit (hosts.${config.networking.hostName}) interfaces;
  inherit (tools.meta) domain;
  inherit (config.links) pdnsAdmin;
  inherit (cluster.config) vars;

  pdns-api = cluster.config.links.powerdns-api;

  dataDirUI = "/srv/storage/private/powerdns-admin";

  translateConfig = withQuotes: cfg: let
    pythonValue = val: if lib.isString val then "'${val}'"
      else if lib.isAttrs val && val ? env then "__import__('os').getenv('${val.env}')"
      else if lib.isBool val then (if val then "True" else "False")
      else if lib.isInt val then toString val
      else throw "translateConfig: unsupported value type";

    quote = str: if withQuotes then pythonValue str else str;

    configList = lib.mapAttrsToList (n: v: "${n}=${quote v}") cfg;
  in lib.concatStringsSep "\n" configList;

  login = x: "https://login.${domain}/auth/realms/master/protocol/openid-connect/${x}";
in {
  age.secrets = {
    pdns-admin-oidc-secrets = {
      file = ./pdns-admin-oidc-secrets.age;
      mode = "0400";
    };
    pdns-admin-salt = {
      file = ./pdns-admin-salt.age;
      mode = "0400";
      owner = "powerdnsadmin";
      group = "powerdnsadmin";
    };
    pdns-admin-secret = {
      file = ./pdns-admin-secret.age;
      mode = "0400";
      owner = "powerdnsadmin";
      group = "powerdnsadmin";
    };
    pdns-api-key = {
      file = ./pdns-api-key.age;
      mode = "0400";
    };
  };

  links.pdnsAdmin.protocol = "http";

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  systemd.tmpfiles.rules = [
    "d '${dataDirUI}' 0700 powerdnsadmin powerdnsadmin - -"
  ];

  services.powerdns = {
    enable = true;
    extraConfig = translateConfig false {
      api = "yes";
      webserver-allow-from = "127.0.0.1, ${vars.meshNet.cidr}";
      webserver-address = pdns-api.ipv4;
      webserver-port = pdns-api.portStr;
      api-key = "$scrypt$ln=14,p=1,r=8$ZRgztsniH1y+F7P/RkXq/w==$QTil5kbJPzygpeQRI2jgo5vK6fGol9YS/NVR95cmWRs=";
    };
  };

  services.powerdns-admin = {
    enable = true;
    secretKeyFile = config.age.secrets.pdns-admin-secret.path;
    saltFile = config.age.secrets.pdns-admin-salt.path;
    extraArgs = [ "-b" pdnsAdmin.tuple ];
    config = translateConfig true {
      SQLALCHEMY_DATABASE_URI = "sqlite:///${dataDirUI}/pda.db";
      PDNS_VERSION = pkgs.pdns.version;
      PDNS_API_URL = pdns-api.url;
      PDNS_API_KEY.env = "PDNS_API_KEY";

      SIGNUP_ENABLED = false;
      OIDC_OAUTH_ENABLED = true;
      OIDC_OAUTH_KEY = "net.privatevoid.dnsadmin1";
      OIDC_OAUTH_SECRET.env = "OIDC_OAUTH_SECRET";
      OIDC_OAUTH_SCOPE = "openid profile email roles";

      OIDC_OAUTH_API_URL = login "";
      OIDC_OAUTH_TOKEN_URL = login "token";
      OIDC_OAUTH_AUTHORIZE_URL = login "auth";
      OIDC_OAUTH_LOGOUT_URL = login "logout";
    };
  };

  systemd.services.powerdns-admin.serviceConfig = {
    BindPaths = [ dataDirUI ];
    EnvironmentFile = [
      config.age.secrets.pdns-api-key.path
      config.age.secrets.pdns-admin-oidc-secrets.path
    ];
  };

  services.nginx.virtualHosts."dnsadmin.${domain}" = lib.recursiveUpdate
  (tools.nginx.vhosts.proxy pdnsAdmin.url)
  # backend sends really big headers for some reason
  # increase buffer size accordingly
  {
    locations."/".extraConfig = ''
      proxy_busy_buffers_size 512k;
      proxy_buffers 4 512k;
      proxy_buffer_size 256k;
    '';
  };
}
