{ lib, pkgs, ... }:

let
  idmReady = pkgs.writers.writeHaskellBin "idm-nss-ready" {
    libraries = with pkgs.haskellPackages; [ watchdog ];
  } ''
    import Control.Monad.IO.Class
    import Control.Watchdog
    import System.IO
    import System.IO.Error
    import System.Posix.User

    flushLogger :: WatchdogLogger String
    flushLogger taskErr delay = do
      defaultLogger taskErr delay
      hFlush stdout

    main :: IO ()
    main = watchdog $ do
      setInitialDelay 300_000
      setMaximumDelay 30_000_000
      setLoggingAction flushLogger
      watch $ do
        check <- liftIO $ tryIOError $ getGroupEntryForName "infra_admins"
        case check of
          Right _ -> return $ Right ()
          Left _ -> return $ Left "group not found"
  '';
in

{
  systemd.services.idm-nss-ready = {
    description = "Wait for IDM NSS";
    requires = [ "kanidm-unixd.service" "nss-user-lookup.target" ];
    after = [ "kanidm-unixd.service" ];
    before = [ "nss-user-lookup.target" ];
    serviceConfig = {
      ExecStart = lib.getExe idmReady;
      DynamicUser = true;
      TimeoutStartSec = "2m";
      Type = "oneshot";
    };
  };
}
