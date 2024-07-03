{ lib, name, ... }:

with lib;

{
  options = {
    internal = mkOption {
      description = "Whether to only make this Way available internally. Will use the internal subdomain.";
      type = types.bool;
      default = false;
    };

    name = mkOption {
      description = "Subdomain name to use.";
      type = types.str;
      default = name;
    };

    target = mkOption {
      type = types.str;
    };

    healthCheckPath = mkOption {
      type = types.path;
      default = "/.well-known/ways/internal-health-check";
    };

    extras = mkOption {
      description = "Extra configuration to pass to the nginx virtual host submodule.";
      type = types.deferredModule;
      default = {};
    };
  };
}
