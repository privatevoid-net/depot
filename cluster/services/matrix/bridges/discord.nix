{ config, tools, ... }:
let
  inherit (tools.meta) domain;
in
{
  age.secrets = {
    matrix-appservice-discord-token = {
      file = ../../../../secrets/matrix-appservice-discord-token.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
  services.matrix-appservice-discord = {
    enable = true;
    environmentFile = config.age.secrets.matrix-appservice-discord-token.path;
    settings = {
      bridge = {
        inherit domain;
        homeserverUrl = "https://matrix.${domain}:443";
        disablePresence = false;
        disableTypingNotifications = false;
        disableDeletionForwarding = false;
        enableSelfServiceBridging = true;
        disableReadReceipts = false;
        disableJoinLeaveNotifications = true;
      };
    };
  };
}
