{ nixosTest, searxng, writeText }:

nixosTest {
  name = "searxng";
  nodes.machine =  {
    services.searx = {
      enable = true;
      runInUwsgi = true;
      package = searxng;
      settings.server.secret_key = "NixOSTestKey";
      uwsgiConfig.http = "0.0.0.0:8080";
    };
  };
  testScript = ''
    machine.wait_for_unit("uwsgi.service")
    machine.wait_for_open_port(8080)
    machine.wait_until_succeeds("curl --fail http://127.0.0.1:8080/")
  '';
}
