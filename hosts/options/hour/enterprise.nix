{ lib, ... }:
with lib;

{
  options.enterprise = {
    subdomain = mkOption {
      description = "Host FQDN subdomain.";
      type = types.str;
      default = "services";
    };
  };
}
