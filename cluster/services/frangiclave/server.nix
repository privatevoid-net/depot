{ depot, ... }:

{
  services.vault = {
    enable = true;
    package = depot.packages.openbao;
  };
}
