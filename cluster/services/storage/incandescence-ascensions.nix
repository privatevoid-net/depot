{ config, lib, ... }:

{
  system.ascensions = {
    incandescence-garage = lib.mkIf (config.services.incandescence.providers ? garage) {
      incantations = i: [
        (i.runGarage /*bash*/ ''
          garage bucket list | tail -n +2 | cut -d' ' -f3 | while read bucket; do
            ${i.runConsul /*bash*/ ''consul kv put "services/incandescence/providers/garage/formulae/bucket/$1/alive" true''} "$bucket"
          done
          garage key list | tail -n +2 | cut -d' ' -f5 | while read key; do
            ${i.runConsul /*bash*/ ''consul kv put "services/incandescence/providers/garage/formulae/key/$1/alive" true''} "$key"
          done
        '')
      ];
    };
  };
}
