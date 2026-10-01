{ cluster, config, depot, depot', lib, pkgs, ... }:

let
  link = cluster.config.hostLinks.${config.networking.hostName}.vineyard;
in

{
  imports = [
    depot.inputs.vineyard.nixosModules.vineyard
  ];

  services.vineyard = {
    enable = true;
    listen = link.tuple;
    publicUrl = "wss://relay.manic.systems/";
    forgePubkeys = [
      "b21e4a3965689e4a24987fae9859d23aeca42b3611ad138ab903bd148e53b185"
    ];
    peers = [
      {
        url = "wss://relay.lobotomise.me";
      }
    ];
  };
}
