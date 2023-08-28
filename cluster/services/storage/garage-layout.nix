{ config, ... }:

let
  initialLayout = ''
    garage layout assign -z eu-central -c 1000 28071b8673ad14c2 # checkmate
    garage layout assign -z eu-central -c 1000 124d6acad43e5f70 # prophet
    garage layout assign -z eu-central -c 1000 e354a1a70adc45c9 # VEGAS
  '';
in

{
  system.ascensions.garage-layout = {
    distributed = true;
    requiredBy = [ "garage.service" ];
    after = [ "garage.service" "garage-layout-init.service" ];
    incantations = i: [ ];
  };

  systemd.services.garage-layout-init = {
    distributed.enable = true;
    wantedBy = [ "garage.service" ];
    after = [ "garage.service" ];
    path = [ config.services.garage.package ];

    script = ''
      while ! garage status >/dev/null 2>/dev/null; do
        sleep 1
      done

      if [[ "$(garage layout show | grep -m1 '^Current cluster layout version:' | cut -d: -f2 | tr -d ' ')" != "0" ]]; then
        exit 0
      fi

      ${initialLayout}

      garage layout apply --version 1
    '';
  };
}
