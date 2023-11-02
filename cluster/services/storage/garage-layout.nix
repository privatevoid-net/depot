{
  system.ascensions.garage-layout = {
    distributed = true;
    requiredBy = [ "garage.service" ];
    after = [ "garage.service" "garage-layout-init.service" ];
    incantations = i: [
      (i.runGarage ''
        garage layout remove "$(getNodeId checkmate)"
        garage layout apply --version 2
      '')
    ];
  };

  services.garage.layout.initial = {
    prophet = { zone = "eu-central"; capacity = 1000; };
    VEGAS = { zone = "eu-central"; capacity = 1000; };
  };
}
