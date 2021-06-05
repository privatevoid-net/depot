rec {
  dirfilter = type: path:
    (let root = builtins.readDir path;
    in builtins.filter (x: builtins.getAttr x root == type)
    (builtins.attrNames root));

  absolutify = path: ../../. + ("/" + path);
  mkpatchlist = pkg:
    map (patch: absolutify (builtins.concatStringsSep "/" [ pkg patch ]))
    (dirfilter "regular" (absolutify pkg));

  patch = super: patchdir:
    super.overrideAttrs
    (attrs: { patches = (attrs.patches or [ ]) ++ (mkpatchlist patchdir); });

  patch-rename = super: pname: patchdir:
    super.overrideAttrs (attrs: {
      patches = (attrs.patches or [ ]) ++ (mkpatchlist patchdir);
      inherit pname;
    });

  patch-rename-direct = super: renameWith: patchdir:
    super.overrideAttrs (attrs: {
      patches = (attrs.patches or [ ]) ++ (mkpatchlist patchdir);
      name = renameWith attrs;
    });
}
