let toolsets = {
    meta = import ./meta.nix;

    identity = import ./identity.nix { inherit toolsets; };
  };
in toolsets // {
  all = args: (builtins.mapAttrs (_: x: x args) toolsets) // { inherit (toolsets) meta; };
}
