{ pkgs, config, ... }:
{
  services.ipfs = {
    enable = true;
    extraConfig = {
      Bootstrap = [
        "/ip4/95.216.8.12/tcp/4001/p2p/Qmd7QHZU8UjfYdwmjmq1SBh9pvER9AwHpfwQvnvNo3HBBo"
        "/ip4/34.75.66.204/tcp/4001/p2p/QmUDwdaJthQkxgoHN1QQFvj4jR12A2nGQMXxYJEqtPMsYJ"
        "/ip4/35.233.49.84/tcp/4001/p2p/QmTuZN9VtqiVWjcqTkRAUnRWYurwFbC6j9E2gvnMs5XEFy"
      ];
    };
  };

  systemd.services.ipfs.environment.LIBP2P_FORCE_PNET = "1";

  environment.shellAliases = {
    ipfs =
      "doas -u ${config.services.ipfs.user} env IPFS_PATH=${config.services.ipfs.dataDir} ipfs";
    f =
      "doas -u ${config.services.ipfs.user} env IPFS_PATH=${config.services.ipfs.dataDir} ipfs files";
  };
}
