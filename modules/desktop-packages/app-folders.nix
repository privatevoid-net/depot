{ depot', pkgs, ... }:

{
  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/shell" = {
          favorite-apps = [
            "org.chromium.Chromium.desktop"
            "org.gnome.Nautilus.desktop"
            "org.gnome.Fractal.desktop"
            "org.gnome.Geary.desktop"
            "org.gnome.Calendar.desktop"
            "com.raggesilver.BlackBox.desktop"
            "org.zedless.Zedless.desktop"
          ];
        };
      };
    }
  ];

  desktop.appFolders = {
    Utilities = {
      name = "X-GNOME-Utilities.directory";
      translate = true;
      categories = [ "X-GNOME-Utilities" ];
      apps = [
        { package = pkgs.blackbox-terminal; appId = "com.raggesilver.BlackBox"; }
        { package = pkgs.baobab; appId = "org.gnome.baobab"; }
        { appId = "org.gnome.Calculator"; }
        { package = pkgs.gnome-font-viewer; appId = "org.gnome.font-viewer"; }
        { appId = "org.gnome.Screenshot"; }
        { package = pkgs.seahorse; appId = "org.gnome.seahorse.Application"; }
        { package = pkgs.junction; appId = "re.sonny.Junction"; }
        { appId = "org.gnome.Characters"; }
      ];
    };

    Files.apps = [
      { appId = "org.gnome.Nautilus"; }
      { appId = "org.gnome.FileRoller"; }
      { package = pkgs.warp; appId = "app.drey.Warp"; }
      # { package = depot'.packages.fragments-remote; appId = "de.haeckerfelix.Fragments"; }
      { package = pkgs.deja-dup; appId = "org.gnome.DejaDup"; }
    ];

    System.apps = [
      { appId = "nixos-manual"; }
      { appId = "org.gnome.Settings"; }
      { package = pkgs.dconf-editor; appId = "ca.desrt.dconf-editor"; }
      { appId = "org.gnome.Extensions"; }
      { package = pkgs.gnome-tweaks; appId = "org.gnome.tweaks"; }
    ];

    Hardware.apps = [
      { appId = "org.gnome.SystemMonitor"; }
      { package = pkgs.gnome-firmware; appId = "org.gnome.Firmware"; }
      { package = pkgs.gnome-disk-utility; appId = "org.gnome.DiskUtility"; }
    ];

    Office.apps = [
      { package = pkgs.libreoffice; appId = "writer"; }
      { appId = "calc"; }
      { appId = "impress"; }
      { appId = "draw"; }
      { appId = "math"; }
      { appId = "base"; }
      { package = pkgs.morphosis; appId = "garden.jamie.Morphosis"; }
      { appId = "org.gnome.Papers"; }
      { package = pkgs.pdfarranger; appId = "com.github.jeromerobert.pdfarranger"; }
    ];

    Graphics.apps = [
      { package = pkgs.drawing; appId = "com.github.maoschanz.drawing"; }
      { package = pkgs.inkscape; appId = "org.inkscape.Inkscape"; }
      { package = pkgs.gimp; appId = "gimp"; }
      { package = pkgs.delineate; appId = "io.github.seadve.Delineate"; }
      { package = pkgs.switcheroo; appId = "io.gitlab.adhami3310.Converter"; }
      { package = pkgs.gnome-obfuscate; appId = "com.belmoussaoui.Obfuscate"; }
      { appId = "org.gnome.Loupe"; }
    ];

    Development.apps = [
      { package = pkgs.emblem; appId = "org.gnome.design.Emblem"; }
      { package = pkgs.forge-sparks; appId = "com.mardojai.ForgeSparks"; }
      { package = depot'.inputs.zedless.packages.zedless; appId = "org.zedless.Zedless"; }
    ];

    Writing.apps = [
      { package = pkgs.apostrophe.override { texliveMedium = pkgs.emptyDirectory; }; appId = "org.gnome.gitlab.somas.Apostrophe"; }
      { package = pkgs.gnome-text-editor; appId = "org.gnome.TextEditor"; }
      { package = pkgs.rnote; appId = "com.github.flxzt.rnote"; }
      { package = pkgs.citations; appId = "org.gnome.World.Citations"; }
    ];

    Games.apps = [
      { appId = "steam"; }
      { appId = "org.polymc.PolyMC"; }
      # { package = depot'.packages.keypunch; appId = "dev.bragefuglseth.Keypunch.Devel"; }
    ];

    Machines.apps = [
      { package = pkgs.gnome-boxes; appId = "org.gnome.Boxes"; }
      { package = pkgs.gnome-connections; appId = "org.gnome.Connections"; }
      { package = pkgs.scrcpy; appId  = "scrcpy"; }
    ];

    PIM.apps = [
      { package = pkgs.gnome-contacts; appId = "org.gnome.Contacts"; }
      { package = pkgs.endeavour; appId = "org.gnome.Todo"; }
      { package = pkgs.gnome-calendar; appId = "org.gnome.Calendar"; }
      { package = pkgs.denaro; appId = "org.nickvision.money"; }
      { package = pkgs.geary; appId = "org.gnome.Geary"; }
      { package = pkgs.passes; appId = "me.sanchezrodriguez.passes"; }
    ];

    Web.apps = [
      { package = pkgs.epiphany; appId = "org.gnome.Epiphany"; }
      { appId = "org.chromium.Chromium"; }
      { package = pkgs.share-preview; appId = "com.rafaelmardojai.SharePreview"; }
      { package = pkgs.cartero; appId = "es.danirod.Cartero"; }
      { package = pkgs.parabolic; appId = "org.nickvision.tubeconverter"; }
    ];

    Ontology.apps = [
      { package = pkgs.newsflash; appId = "io.gitlab.news_flash.NewsFlash"; }
      { appId = "org.gnome.Maps"; }
      { package = pkgs.gnome-weather; appId = "org.gnome.Weather"; }
      { appId = "app.drey.Dialect"; }
      # { package = depot'.packages.wike; appId = "com.github.hugolabe.Wike"; }
      { package = pkgs.gnome-clocks; appId = "org.gnome.clocks"; }
      { package = pkgs.wordbook; appId = "dev.mufeed.Wordbook"; }
      { package = pkgs.diebahn; appId = "de.schmidhuberj.DieBahn"; }
    ];

    Multimedia.apps = [
      { appId = "io.bassi.Amberol"; }
      { package = pkgs.monophony; appId = "io.gitlab.zehkira.Monophony"; }
      { package = pkgs.celluloid; appId = "io.github.celluloid_player.Celluloid"; }
      { package = pkgs.gnome-podcasts; appId = "org.gnome.Podcasts"; }
      # { package = depot'.packages.pipeline; appId = "de.schmidhuberj.tubefeeder"; }
      { package = pkgs.plattenalbum; appId = "de.wagnermartin.Plattenalbum"; }
    ];

    "Media Production".apps = [
      { package = pkgs.obs-studio; appId = "com.obsproject.Studio"; }
      { package = pkgs.tenacity; appId = "tenacity"; }
      { package = pkgs.gnome-sound-recorder; appId = "org.gnome.SoundRecorder"; }
      { package = pkgs.decibels; appId = "org.gnome.Decibels"; }
    ];

    "Text Processing".apps = [
      { package = pkgs.wildcard; appId = "net.ffkkinos.Wildcard"; }
      { package = pkgs.textpieces; appId = "io.gitlab.liferooter.TextPieces"; }
      { appId = "org.gnome.gitlab.cheywood.Buffer"; }
    ];

    Introspection.apps = [
      { package = pkgs.wireshark; appId = "org.wireshark.Wireshark"; }
      { package = pkgs.d-spy; appId = "org.gnome.dspy"; }
      { package = pkgs.bustle; appId = "org.freedesktop.Bustle"; }
      { package = pkgs.sysprof; appId = "org.gnome.Sysprof"; }
    ];

    Communication = {
      categories = [
        "Chat"
        "InstantMessaging"
        "VideoConference"
      ];
      apps = [
        { package = pkgs.fractal; appId = "org.gnome.Fractal"; }
      ];
    };
  };

  desktop.hiddenApps = [
    "scrcpy-console.desktop"
    "startcenter.desktop" # LibreOffice Start Center
    "xsltfilter.desktop" # LibreOffice XSLT based filters
  ];
}
