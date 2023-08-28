let
  dataDir = "/srv/storage/private/garage";
in

{
  systemd.tmpfiles.rules = [
    "d '${dataDir}' 0700 garage garage -"
  ];

  services.garage.settings.data_dir = dataDir;
}
