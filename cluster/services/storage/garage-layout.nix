{
  system.ascensions.garage-layout.incantations = i: [
    (i.runGarage ''
      garage layout assign -z eu-central -c 1000GB 124d6acad43e5f70 72121ac2a9ca77ca e354a1a70adc45c9
      garage layout apply --version 2
    '')
  ];

  services.garage.layout.initial = {
    grail = { zone = "eu-central"; capacity = 1000; };
    prophet = { zone = "eu-central"; capacity = 1000; };
    VEGAS = { zone = "eu-central"; capacity = 1000; };
  };
}
