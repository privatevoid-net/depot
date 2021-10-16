let toolsets = {
    meta = import ./meta.nix;
  };
in toolsets // {
  all = args: (builtins.mapAttrs (_: x: x args) toolsets) // { inherit (toolsets) meta; };
}
