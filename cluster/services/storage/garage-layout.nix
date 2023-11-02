{
  system.ascensions.garage-layout = {
    distributed = true;
    requiredBy = [ "garage.service" ];
    after = [ "garage.service" "garage-layout-init.service" ];
    incantations = i: [
    ];
  };

  services.garage.layout.initial = {
    prophet = { zone = "eu-central"; capacity = 1000; };
    VEGAS = { zone = "eu-central"; capacity = 1000; };
  };
}
