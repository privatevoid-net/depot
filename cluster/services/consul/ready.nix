{ config, lib, pkgs, ... }:

let
  consulReady = pkgs.writers.writeHaskellBin "consul-ready" {
    libraries = with pkgs.haskellPackages; [ aeson http-conduit watchdog ];
  } ''
    {-# LANGUAGE OverloadedStrings #-}
    import Control.Watchdog
    import Control.Exception
    import System.IO
    import Network.HTTP.Simple
    import Data.Aeson

    flushLogger :: WatchdogLogger String
    flushLogger taskErr delay = do
      defaultLogger taskErr delay
      hFlush stdout

    data ConsulHealth = ConsulHealth {
      healthy :: Bool
    }

    instance FromJSON ConsulHealth where
      parseJSON (Object v) = ConsulHealth <$> (v .: "Healthy")

    handleException ex = case ex of
      (SomeException _) -> return $ Left "Consul is not active"

    main :: IO ()
    main = watchdog $ do
      setInitialDelay 300_000
      setMaximumDelay 30_000_000
      setLoggingAction flushLogger
      watch $ handle handleException $ do
          res <- httpJSON "${config.links.consulAgent.url}/v1/operator/autopilot/health"
          case getResponseBody res of
            ConsulHealth True -> return $ Right ()
            ConsulHealth False -> return $ Left "Consul is unhealthy"
  '';
in

{
  systemd.services.consul-ready = {
    description = "Wait for Consul";
    requires = lib.mkIf config.services.consul.enable [ "consul.service" ];
    after = lib.mkIf config.services.consul.enable [ "consul.service" ];
    serviceConfig = {
      ExecStart = lib.getExe consulReady;
      DynamicUser = true;
      TimeoutStartSec = "5m";
      Type = "oneshot";
      StartLimitBurst = 25;
    };
  };
}
