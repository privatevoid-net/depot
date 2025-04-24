{ config, lib, pkgs, ... }:

{
  networking.firewall = {
      enable = true;
      extraCommands = let
        ip4Ranges = [
        ];

        dropIncoming = iptables: set: lib.escapeShellArgs [
          iptables
          "-I" "nixos-fw" 1
          "-i" config.reflection.interfaces.primary.link
          "-m" "conntrack"
          "--ctstate" "NEW,INVALID" # connections for me, but not for thee
          "-m" "set"
          "--match-set" set "src"
          "-j" "DROP"
        ];

        block = set: map (as: ''
          ${pkgs.jq}/bin/jq < ${as} --raw-output0 '.[]' | xargs --no-run-if-empty -0 -n1 ${pkgs.ipset}/bin/ipset add ${lib.escapeShellArg set}
        '');

        rules4 = block "geoblockv4new" [
          # scrapers with generic user agents
          ./ranges/v4/as136907.json # huawei
          ./ranges/v4/as45102.json # alibaba
          ./ranges/v4/as132203.json # tencent
        ];
      in ''
        ${pkgs.ipset}/bin/ipset -exist destroy geoblockv4new
        ${pkgs.ipset}/bin/ipset -exist create geoblockv4 hash:net family inet
        ${pkgs.ipset}/bin/ipset -exist create geoblockv4new hash:net family inet
        ${lib.concatStringsSep "\n" rules4}
        ${dropIncoming "iptables" "geoblockv4"}
        ${pkgs.ipset}/bin/ipset swap geoblockv4 geoblockv4new
        ${pkgs.ipset}/bin/ipset destroy geoblockv4new
      '';
    };
}
