{ tools, ... }:

{
  monitoring.blackbox.targets.soda-machine = {
    address = "soda.int.${tools.meta.domain}:22";
    module = "sshConnect";
  };
}
