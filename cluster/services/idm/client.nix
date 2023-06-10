{ cluster, pkgs, ... }:

let
  frontendLink = cluster.config.links.idm;
in

{
  services.kanidm = {
    enableClient = true;
    clientSettings = {
      uri = frontendLink.url;
    };
  };

  environment.systemPackages = let
    idmAlias = pkgs.runCommand "kanidm-idm-alias" {} ''
      mkdir -p $out/bin
      ln -s ${pkgs.kanidm}/bin/kanidm $out/bin/idm
      mkdir -p $out/share/bash-completion/completions
      cat >$out/share/bash-completion/completions/idm.bash <<EOF
      source ${pkgs.kanidm}/share/bash-completion/completions/kanidm.bash
      complete -F _kanidm -o bashdefault -o default idm
      EOF
    '';
  in [ idmAlias ];
}
