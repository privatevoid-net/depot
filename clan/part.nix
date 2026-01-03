{ depot, ... }:

{
  clan = {
    meta = {
      name = "void";
      description = "Private Void";
      inherit (depot.lib.meta) domain;
    };
  };
}
