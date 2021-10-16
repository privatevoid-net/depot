let toolsets = {
    meta = import ./meta.nix;

    acme = import ./acme.nix { inherit toolsets; };
    identity = import ./identity.nix { inherit toolsets; };
    networks = import ./networks.nix { inherit toolsets; };
    nginx = import ./nginx.nix { inherit toolsets; };
  };
in toolsets // {
  all = args: (builtins.mapAttrs (_: x: x args) toolsets) // { inherit (toolsets) meta; };
}
