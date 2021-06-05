{
  dns = rec {
    findSvc = name: [
      "any.${name}"
      "local.${name}"
      "tunnel.${name}"
      "wired.${name}"
      "wireless.${name}"
      "*.if.${name}"
    ];
    findResolve = list: dnameResolve (append "find" list) ++ append "f.void" list;
    dnameResolve = list: append "private.void" list ++ append "privatevoid.net" list;
    vpnResolve = list: dnameResolve (append "vpn" list);
    llmnrResolve = append "local";
    append = part: map (x: "${x}.${part}");
    portMap = port: map (x: "[${x}]:${builtins.toString port}");
    as = x: [x];

    clientResolve = x: [x] ++
      findResolve (findSvc x) ++
      vpnResolve [x] ++
      llmnrResolve [x];

    subResolve = name: sub: [name] ++ dnameResolve ["${name}.${sub}"];
  };
  ssh = {
    extraConfig = patterns: config: with builtins; let
      match = "Host ${concatStringsSep " " patterns}";
      indent = map (x: "    " + x) config;
    in concatStringsSep "\n" ([match] ++ indent);
  };
}
