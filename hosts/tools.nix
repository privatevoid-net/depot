{
  dns = rec {
    dnameResolve = list: append "privatevoid.net" list;
    append = part: map (x: "${x}.${part}");
    portMap = port: map (x: "[${x}]:${builtins.toString port}");
    as = x: [x];
    subResolve = name: sub: [name] ++ dnameResolve ["${name}.${sub}"];
  };
  ssh = {
    extraConfig = patterns: config: with builtins; let
      match = "Host ${concatStringsSep " " patterns}";
      indent = map (x: "    " + x) config;
    in concatStringsSep "\n" ([match] ++ indent);
  };
}
