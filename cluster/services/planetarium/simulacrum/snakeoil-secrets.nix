{ ... }:
{
  environment.etc."dummy-secrets/cluster-planetarium-storageCredentials".text = ''
    AWS_ACCESS_KEY_ID=simulacrum
    AWS_SECRET_ACCESS_KEY=simulacrum
  '';
}
