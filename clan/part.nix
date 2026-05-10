{ depot, ... }:

{
  imports = [
    ./adapter.nix
    ./inventory/ssh.nix
  ];

  clan = {
    meta = {
      name = "void";
      description = "Private Void";
      inherit (depot.lib.meta) domain;
    };
  };
}
