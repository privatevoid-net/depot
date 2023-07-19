{
  services.grafana-agent.settings.integrations.blackbox = {
    blackbox_targets = [
      {
        name = "default/anon-relay";
        module = "tcpConnect";
        address = "10.64.0.1:1080";
      }
    ];
  };
}
