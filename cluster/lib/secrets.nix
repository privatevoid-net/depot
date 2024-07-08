{ lib, ... }:

{
  options.secrets = {
    extraKeys = lib.mkOption {
      type = with lib.types; listOf str;
      description = "Additional keys with which to encrypt all secrets.";
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL max@TITAN"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmdWfmAs/0rno8zJlhBFMY2SumnHbTNdZUXJqxgd9ON max@jericho"
      ];
    };
  };
}
