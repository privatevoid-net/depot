{
  lib = { config, ... }: with config.meta; {
    meta = {
      domain = "privatevoid.net";
      adminEmail = "admins@${domain}";
    };
  };
}
