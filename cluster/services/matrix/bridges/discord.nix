{ cluster, depot, ... }:
let
  inherit (depot.lib.meta) domain;
in
{
  services.matrix-appservice-discord = {
    enable = true;
    environmentFile = cluster.config.services.matrix.secrets.discordAppServiceToken.path;
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
