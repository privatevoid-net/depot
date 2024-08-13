{ lib, config, ... }: {
  config.environment.etc = {
    "dummy-secrets/cluster-wireguard-meshPrivateKey".source = lib.mkForce ./keys/snakeoilPrivateKey-${config.networking.hostName};
    "dummy-secrets/wireguard-key-storm".source = lib.mkForce ./keys/snakeoilPrivateKey-${config.networking.hostName};
  };
}
