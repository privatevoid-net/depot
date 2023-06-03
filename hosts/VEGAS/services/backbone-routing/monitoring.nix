{
  services.grafana-agent.settings.integrations.blackbox = {
    blackbox_targets = [
      {
        name = "default/autobahn";
        module = "tcpConnect";
        address = "10.15.0.2:80";
      }
      {
        name = "default/anon-relay";
        module = "tcpConnect";
        address = "10.64.0.1:1080";
      }
    ];
  };
}
