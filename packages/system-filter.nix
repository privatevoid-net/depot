{
  packages = {
    cinny = [ "x86_64-linux" ];
    dvc = [ "x86_64-linux" ];
    grafana = [ "x86_64-linux" ];
    hci = [ ];
    hydra = [ "x86_64-linux" ];
    keycloak = [ "x86_64-linux" ];
    prometheus-jitsi-exporter = [ "aarch64-linux" ];
    searxng = [ "x86_64-linux" ];
    sips = [ "x86_64-linux" ];
    tempo = [ "x86_64-linux" ];
    uptime-kuma = [ "x86_64-linux" ];
  };
  checks = {
    keycloak = [ "x86_64-linux" ];
    patroni = [ "x86_64-linux" ];
    tempo = [ "x86_64-linux" ];
  };
}
