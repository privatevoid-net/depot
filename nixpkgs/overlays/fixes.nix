{
  flake.overlays.fixes = final: prev: {
    gnome-control-center = prev.gnome-control-center.overrideAttrs (old: {
      preBuild = (old.preBuild or "") + ''
        ninja panels/sound/cc-sound-panel.ui panels/system/about/cc-about-page.ui

        ${final.xmlstarlet}/bin/xmlstarlet edit -L \
          -s '//property[@name="title" and text()="_Alert Sound"]/..' -t elem -n propertyAlertSoundVisible -v False \
          -s //propertyAlertSoundVisible -t attr -n name -v visible \
          -r //propertyAlertSoundVisible -v property \
          panels/sound/cc-sound-panel.ui
        test "$(${final.xmlstarlet}/bin/xmlstarlet select -t -c '//property[@name="title" and text()="_Alert Sound"]/../property[@name="visible"]/text()' panels/sound/cc-sound-panel.ui)" == "False"

        ${final.xmlstarlet}/bin/xmlstarlet edit -L \
          -s '//property[@name="title" and text()="Support GNOME"]/..' -t elem -n propertyDonateVisible -v False \
          -s //propertyDonateVisible -t attr -n name -v visible \
          -r //propertyDonateVisible -v property \
          panels/system/about/cc-about-page.ui
        test "$(${final.xmlstarlet}/bin/xmlstarlet select -t -c '//property[@name="title" and text()="Support GNOME"]/../property[@name="visible"]/text()' panels/system/about/cc-about-page.ui)" == "False"
      '';
    });
  };
}
