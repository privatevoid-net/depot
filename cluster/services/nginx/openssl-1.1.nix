{ pkgs, ... }:

{
  services.nginx.package = pkgs.nginx.override {
    openssl = pkgs.openssl_1_1;
  };
}
