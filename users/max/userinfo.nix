pkgs: rec {
  firstName = "Max";
  lastName = "Headroom";
  userName = "max";
  orgDomain = "privatevoid.net";

  security = { pkcs11Providers = [ "${pkgs.opensc}/lib/opensc-pkcs11.so" ]; };

  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5C7mC5S2gM0K6x0L/jNwAeQYbFSzs16Q73lONUlIkL max@TITAN"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmdWfmAs/0rno8zJlhBFMY2SumnHbTNdZUXJqxgd9ON max@jericho"
  ];

  email = "${userName}@${orgDomain}";
  gecos = "${firstName} ${lastName}";
}
