{ depot, ... }:

{
  imports = [
    ./adapter.nix
    ./inventory/admin.nix
  ];

  clan = {
    meta = {
      name = "void";
      description = "Private Void";
      inherit (depot.lib.meta) domain;
    };
  };
}
