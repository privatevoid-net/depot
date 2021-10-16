let
  entry = { directory, network, security ? "krb5i", writable ? true, options ? [] }:
  let
    mode = if writable then "rw" else "ro";
    optionsFinal = [ mode "sec=${security}" ] ++ options;
    concat = builtins.concatStringsSep "," optionsFinal;
  in "${directory} ${network}(${concat})";

  exports = map entry [
    { directory = "/srv/storage/www/soda"; network = "10.10.2.0/24"; options = [ "no_root_squash" ]; }
  ];
in {
  services.nfs.server.exports = builtins.concatStringsSep "\n" exports;
}
